from __future__ import annotations

import argparse
import binascii
import gzip
import ipaddress
import json
import os
import shutil
import subprocess
import sys
import time
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import IO, TYPE_CHECKING, NoReturn

if TYPE_CHECKING:
    from collections.abc import Iterator

FILE = None | int | IO

NIXOS_ANYWHERE_SH = Path(__file__).parent.absolute() / "src/nixos-anywhere.sh"



def run(
    cmd: str | list[str],
    input: str | None = None,  # noqa: A002
    stdout: FILE = None,
    stderr: FILE = None,
    extra_env: dict[str, str] | None = None,
    cwd: None | str | Path = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    if extra_env is None:
        extra_env = {}
    shell = False
    if isinstance(cmd, str):
        cmd = [cmd]
        shell = True
    displayed_cmd = " ".join(cmd)
    print(f"$ {displayed_cmd}")
    env = os.environ.copy()
    env.update(extra_env)
    return subprocess.run(
        cmd,
        shell=shell,
        input=input,
        stdout=stdout,
        stderr=stderr,
        env=env,
        cwd=cwd,
        check=check,
        text=True,
    )


@dataclass
class DhcpEvent:
    action: str
    mac_address: str
    ip_addr: str
    hostname: str | None = None


class Dnsmasq:
    def __init__(self, process: subprocess.Popen, dhcp_fifo_path: Path) -> None:
        self.process = process
        self.dhcp_fifo_path = dhcp_fifo_path

    def next_dhcp_event(self) -> Iterator[DhcpEvent]:
        while True:
            with self.dhcp_fifo_path.open() as f:
                for fifo_line in f:
                    raw_event = json.loads(fifo_line)
                    yield DhcpEvent(**raw_event)
            time.sleep(0.1)


# Whenever a new DHCP lease is created, or an old one destroyed, or a TFTP file
# transfer completes, the executable specified by this option is run.
# <path> must be an absolute pathname, no PATH search occurs.
# The arguments to the process are:
# - "add|old|del"
# 	- "add": means a lease has been created
# 	- "del": means it has been destroyed
# 	- "old": is a notification of an existing lease when dnsmasq starts or a change to
#    	MAC address or hostname of an existing lease (also, lease length or expiry
# 	    and client-id, if leasefile-ro is set).
# - the MAC address of the host (or DUID for IPv6)
# 	- If the MAC address is from a network type other than ethernet, it will have
# 		the network type prepended, eg "06-01:23:45:67:89:ab" for token ring.
# - the IP address
# - and the hostname, if known.
# The process is run as root (assuming that dnsmasq was originally run as root)
# 	even if dnsmasq is configured to change UID to an unprivileged user.
@contextmanager
def start_dnsmasq(
    interface: str,
    dhcp_range: tuple[ipaddress.IPv4Address, ipaddress.IPv4Address],
) -> Iterator[Dnsmasq]:
    with TemporaryDirectory(prefix="dnsmasq.") as _temp:
        temp = Path(_temp)
        dhcp_script = temp / "dhcp-script"
        fifo = temp / "fifo"
        dhcp_script.write_text(
            f"""#!{sys.executable}
import os
import sys
import json
print(sys.argv)
if len(sys.argv) <= 4:
   sys.exit(0)
with open("{fifo}", "w") as f:
    data = dict(action=sys.argv[1], mac_address=sys.argv[2], ip_addr=sys.argv[3])
    if len(sys.argv) >= 5:
        data["hostname"] = sys.argv[4]
    print(json.dumps(data), file=f)
""",
        )
        dhcp_script.chmod(0o700)
        conf = temp / "dnsmasq.conf"
        conf.write_text(
            f"""
leasefile-ro
keep-in-foreground
log-facility=-
dhcp-option=3
dhcp-option=6
dhcp-range={dhcp_range[0]},{dhcp_range[1]},12h
interface={interface}
port=0
dhcp-script={dhcp_script}
        """,
        )
        import time

        time.sleep(1)
        os.mkfifo(fifo, 0o600)
        env = os.environ.copy()
        env["FIFO_PATH"] = str(fifo)
        args = ["dnsmasq", "-C", str(conf)]
        print(f"spawn {' '.join(args)}")
        with subprocess.Popen(args, text=True, env=env) as process:
            try:
                yield Dnsmasq(process, fifo)
            finally:
                print("terminate dnsmasq")
                process.terminate()
                try:
                    process.wait(timeout=4)
                except subprocess.TimeoutExpired:
                    process.kill()
                else:
                    return


@contextmanager
def start_pixiecore(
    server_ip: ipaddress.IPv4Address,
    port: int,
    ssh_public_key: Path,
    pxe_image_store_path: Path,
    hostname: str,
) -> Iterator[subprocess.Popen]:
    with TemporaryDirectory(prefix="pixiecore.") as _temp:
        temp = Path(_temp)
        extra_initrd_root = temp / "extra-initrd"
        authorized_keys = extra_initrd_root / "ssh" / "authorized_keys"
        authorized_keys.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        authorized_keys.write_text(ssh_public_key.read_text())
        uncompressed_initrd_file = temp / "extra-initrd.cpio"
        with uncompressed_initrd_file.open("w+") as f:
            run(
                ["cpio", "-o", "-Hnewc"],
                cwd=extra_initrd_root,
                stdout=f,
                input="./\n./ssh\n./ssh/authorized_keys",
            )
        compressed_initrd_file = temp / "extra-initrd.cpio.gz"

        # compression is needed here since at least the UEFI implementation used
        # in qemu does not like uncompressed.
        with (
            uncompressed_initrd_file.open(mode="rb") as f_in,
            gzip.open(compressed_initrd_file, "wb") as f_out,
        ):
            shutil.copyfileobj(f_in, f_out)

        init = (pxe_image_store_path / "init").resolve()
        cmdline = (pxe_image_store_path / "kernel-params").read_text()
        cmdline += f" boot.shell_on_fail init={init} hostname={hostname}"
        kernel = pxe_image_store_path / "bzImage"
        initrds = [pxe_image_store_path / "initrd", compressed_initrd_file]
        args = list(
            map(
                str,
                [
                    "pixiecore",
                    "boot",
                    kernel,
                    *initrds,
                    "--cmdline",
                    cmdline,
                    "--debug",
                    "--listen-addr",
                    server_ip,
                    "--dhcp-no-bind",
                    "--port",
                    port,
                    "--status-port",
                    port,
                ],
            ),
        )
        print(f"spawn {' '.join(args)}")
        with subprocess.Popen(args, text=True) as process:
            try:
                yield process
            finally:
                process.terminate()
                try:
                    process.wait(timeout=4)
                except subprocess.TimeoutExpired:
                    process.kill()
                else:
                    return


@dataclass
class Options:
    flake: str
    netboot_image_flake: str
    dhcp_interface: str
    dhcp_server_ip: ipaddress.IPv4Address
    dhcp_subnet: int
    dhcp_range: tuple[ipaddress.IPv4Address, ipaddress.IPv4Address]
    pixiecore_http_port: int
    pause_after_completion: bool
    nixos_anywhere_args: list[str]


def die(msg: str) -> NoReturn:
    print(msg, file=sys.stderr)
    sys.exit(1)


def parse_args(args: list[str]) -> Options:
    parser = argparse.ArgumentParser(
        description="Note: All arguments not listed here will be passed on to nixos-anywhere (see `nixos-anywhere --help`).",
    )
    parser.add_argument(
        "--flake",
        help="Flake url of nixos configuration to install",
        required=True,
    )
    parser.add_argument(
        "--netboot-image-flake",
        help="Flake url of netboot image to use for PXE boot",
        default="github:nix-community/nixos-images#netboot-installer-nixos-unstable",
    )
    parser.add_argument(
        "--dhcp-subnet",
        help="ipv4 dhcp subnet to use for dhcp",
        default="192.168.35.0/24",
    )
    parser.add_argument(
        "--dhcp-interface",
        help="DHCP network interface name to bind to i.e. eth0",
        required=True,
    )
    parser.add_argument(
        "--pixiecore-http-port",
        help="Port to listen on for HTTP in pixiecore",
        default=64172,
        type=int,
    )
    parser.add_argument(
        "--pause-after-completion",
        help="Whether to wait for user confirmation before tearing down the network setup once the installation completed",
        action="store_true",
    )

    parsed, unknown_args = parser.parse_known_args(args)
    try:
        dhcp_subnet = ipaddress.ip_network(parsed.dhcp_subnet)
    except ValueError as e:
        die(f"subnet specified in --dhcp-subnet is not valid: {e}")

    if dhcp_subnet.version != 4:
        die(
            "Sorry. Only ipv4 subnets are supported just now because of compatibility with older bios firmware",
        )

    hosts = dhcp_subnet.hosts()
    try:
        dhcp_server_ip = next(hosts)
    except StopIteration:
        die(f"not enough ip addresses found in dhcp-subnet: {parsed.dhcp_subnet}")

    try:
        start_ip = next(hosts)
        stop_ip = start_ip
    except StopIteration:
        die(f"not enough ip addresses found in dhcp-subnet: {parsed.dhcp_subnet}")
    try:
        for _ in range(50):
            stop_ip = next(hosts)
    except StopIteration:
        pass

    return Options(
        flake=parsed.flake,
        netboot_image_flake=parsed.netboot_image_flake,
        dhcp_server_ip=dhcp_server_ip,
        dhcp_subnet=dhcp_subnet.prefixlen,
        dhcp_range=(start_ip, stop_ip),
        dhcp_interface=parsed.dhcp_interface,
        pixiecore_http_port=parsed.pixiecore_http_port,
        pause_after_completion=parsed.pause_after_completion,
        nixos_anywhere_args=unknown_args,
    )


@dataclass
class SshKey:
    private_key: Path
    public_key: Path


@contextmanager
def ssh_private_key() -> Iterator[SshKey]:
    with TemporaryDirectory(suffix="ssh-keys") as _dir:
        temp = Path(_dir)
        private_key = temp / "id_ed25519"
        public_key = temp / "id_ed25519.pub"
        run(["ssh-keygen", "-t", "ed25519", "-f", str(private_key), "-N", ""])
        yield SshKey(private_key=private_key, public_key=public_key)


def nixos_anywhere(
    ip: str,
    flake: str,
    ssh_private_key: Path,
    nixos_anywhere_args: list[str],
) -> None:
    run(
        [
            # FIXME: path
            "bash",
            str(NIXOS_ANYWHERE_SH),
            "--flake",
            flake,
            "-L",
            # do not substitute because we do not have internet and copying locally is faster.
            "--no-substitute-on-destination",
            ip,
        ]
        + nixos_anywhere_args,
        extra_env=dict(SSH_PRIVATE_KEY=ssh_private_key.read_text()),
        check=False,
    )


@contextmanager
def configure_network_interface(interface: str, ip_addr: str) -> Iterator[None]:
    # TODO macos support...
    has_nmcli = shutil.which("nmcli") is not None
    try:
        if has_nmcli:
            # Don't fail execution if networkmanager is not running
            subprocess.run(
                ["nmcli", "device", "set", interface, "managed", "no"],
                check=False,
            )
        # FIXME find a way to avoid this. having multiple ip addresses messes up pixieboot just now.
        run(["ip", "addr", "flush", "dev", interface])
        run(["ip", "addr", "change", str(ip_addr), "dev", interface])
        run(["ip", "link", "set", "dev", interface, "up"])
        try:
            yield
        finally:
            run(["ip", "addr", "del", str(ip_addr), "dev", interface], check=False)
    finally:
        # FIXME: detect if the device was unmanaged before
        if has_nmcli:
            run(["nmcli", "device", "set", interface, "managed", "yes"], check=False)


# FIXME make this just download things?
def build_pxe_image(netboot_image_flake: str) -> Path:
    res = run(
        ["nix", "build", "--print-out-paths", netboot_image_flake],
        stdout=subprocess.PIPE,
    )
    return Path(res.stdout.strip())


def pause() -> None:
    print()
    # no clue how to flush stdin with python. Gonna wait for a specific string instead (as opposed to wait for [enter]).
    answer = ""
    while answer != "continue":
        answer = input(
            "Answer 'continue' to terminate this script and tear down the network to the server: ",
        )


def dispatch_dnsmasq(
    dnsmasq: Dnsmasq,
    options: Options,
    ssh_key: SshKey,
    random_hostname: str,
) -> None:
    seen_devices = set()
    for event in dnsmasq.next_dhcp_event():
        print(f"{event.action} client (mac: {event.mac_address}, ip: {event.ip_addr}")
        if event.action not in ("add", "old"):
            continue
        if event.hostname != random_hostname:
            print(
                f"ignore client {event.hostname or event.mac_address} != {random_hostname}",
            )
            continue
        if event.mac_address in seen_devices:
            print(f"skip already seen device with mac address {event.mac_address}")
        seen_devices.add(event.mac_address)

        print(
            "Will now run nixos-remote on this target. You can also try to connect to the machine by doing:",
        )
        print(f"  ssh -i {ssh_key.private_key} root@{event.ip_addr}")
        nixos_anywhere(
            event.ip_addr,
            options.flake,
            ssh_key.private_key,
            options.nixos_anywhere_args,
        )
        # to avoid having to reboot physical machines all the time because networking disappears:
        if options.pause_after_completion:
            print("You can connect to the machine by doing:")
            print(f"  ssh -i {ssh_key.private_key} root@{event.ip_addr}")
            pause()
        return


def run_nixos_anywhere(options: Options) -> None:
    pxe_image_store_path = build_pxe_image(options.netboot_image_flake)

    random_hostname = f"nixos-pxe-{binascii.b2a_hex(os.urandom(4)).decode('ascii')}"
    with (
        configure_network_interface(
            options.dhcp_interface,
            f"{options.dhcp_server_ip}/{options.dhcp_subnet}",
        ),
        ssh_private_key() as ssh_key,
        start_pixiecore(
            options.dhcp_server_ip,
            options.pixiecore_http_port,
            ssh_key.public_key,
            pxe_image_store_path,
            random_hostname,
        ),
        start_dnsmasq(options.dhcp_interface, options.dhcp_range) as dnsmasq,
    ):
        print("Waiting for a client to install nixos to. Cancel with Ctrl-C!")
        try:
            dispatch_dnsmasq(dnsmasq, options, ssh_key, random_hostname)
        except KeyboardInterrupt:
            print("terminating...")


# switch to https://pojntfx.github.io/go-isc-dhcp/ ?
def main(args: list[str] = sys.argv[1:]) -> None:
    options = parse_args(args)
    if os.geteuid() != 0:
        die("You need to have root privileges to run this script. Exiting.")
    run_nixos_anywhere(options)


if __name__ == "__main__":
    main()

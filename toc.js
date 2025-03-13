// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><a href="requirements.html">System Requirements</a></li><li class="chapter-item expanded affix "><a href="quickstart.html">Quickstart</a></li><li class="chapter-item expanded affix "><a href="howtos/INDEX.html">How to Guide</a></li><li class="chapter-item expanded "><a href="howtos/no-os.html"><strong aria-hidden="true">1.</strong> Installing on a machine with no operating system</a></li><li class="chapter-item expanded "><a href="howtos/custom-kexec.html"><strong aria-hidden="true">2.</strong> Using your own kexec image</a></li><li class="chapter-item expanded "><a href="howtos/secrets.html"><strong aria-hidden="true">3.</strong> Secrets and full disk encryption</a></li><li class="chapter-item expanded "><a href="howtos/use-without-flakes.html"><strong aria-hidden="true">4.</strong> Use without flakes</a></li><li class="chapter-item expanded "><a href="howtos/terraform.html"><strong aria-hidden="true">5.</strong> Terraform</a></li><li class="chapter-item expanded "><a href="howtos/nix-path.html"><strong aria-hidden="true">6.</strong> Nix-channels / NIX_PATH</a></li><li class="chapter-item expanded "><a href="howtos/ipv6.html"><strong aria-hidden="true">7.</strong> IPv6-only targets</a></li><li class="chapter-item expanded affix "><a href="reference.html">Reference</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);

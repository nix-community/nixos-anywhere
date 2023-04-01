package test

import (
	"fmt"
	"io/ioutil"
	"log"
	"testing"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformQemuExample(t *testing.T) {
	tmpDir, err := ioutil.TempDir("", "tf-vms")
	if err != nil {
		log.Fatal(err)
	}

	t.Setenv("TF_DATA_DIR", tmpDir)
	//nolint:exhaustivestruct
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "examples/qemu",
		// Variables to pass to our Terraform code using -var options
		EnvVars: map[string]string{},
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	// Comment this line to keep the vm
	defer terraform.Destroy(t, terraformOptions)

	// Show the plan
	terraform.InitAndPlanE(t, terraformOptions)
	// Apply twice
	terraform.InitAndApplyAndIdempotent(t, terraformOptions)

	ip := terraform.Output(t, terraformOptions, "ipv4")

	publicKey, err := ioutil.ReadFile("../modules/ssh-keys/ssh.pub")
	if err != nil {
		log.Fatal(err)
	}
	privateKey, err := ioutil.ReadFile("../modules/ssh-keys/ssh")
	if err != nil {
		log.Fatal(err)
	}
	keyPair := ssh.KeyPair { PublicKey: string(publicKey), PrivateKey: string(privateKey)}

	host := ssh.Host{
		Hostname:    ip,
		SshKeyPair:  &keyPair,
		SshUserName: "root",
	}
	description := fmt.Sprintf("SSH to VM %s", ip)
	retry.DoWithRetry(t, description, 60, 4, func() (string, error) {
		err := ssh.CheckSshConnectionE(t, host)
		if err != nil {
			return "", fmt.Errorf("Unable to connect using ssh for the moment: %w", err)
		}
		return "", nil
	})
}

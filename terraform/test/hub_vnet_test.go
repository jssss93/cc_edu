package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestHubVNet(t *testing.T) {
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID 환경변수가 필요합니다")

	uniqueID := strings.ToLower(random.UniqueId())
	rgName := fmt.Sprintf("rg-test-hub-%s", uniqueID)
	vnetName := fmt.Sprintf("vnet-hub-test-%s", uniqueID)

	opts := &terraform.Options{
		TerraformDir: "./fixtures/hub-vnet",
		EnvVars: map[string]string{
			"TF_CLI_CONFIG_FILE": "/Users/jongsu/git/js_project/cc_edu/terraform/test/test.tfrc",
		},
		Vars: map[string]interface{}{
			"subscription_id":          subscriptionID,
			"resource_group_name":      rgName,
			"location":                 "koreacentral",
			"vnet_name":                vnetName,
			"vnet_address_space":       []string{"10.0.0.0/16"},
			"gateway_subnet_prefix":    "10.0.0.0/27",
			"firewall_subnet_prefix":   "10.0.1.0/26",
			"management_subnet_prefix": "10.0.2.0/24",
			"tags": map[string]string{
				"environment": "test",
				"owner":       "terratest",
				"project":     "ccedu",
			},
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// 출력값 검증
	vnetID := terraform.Output(t, opts, "vnet_id")
	assert.NotEmpty(t, vnetID, "vnet_id 출력값이 비어있음")
	assert.Contains(t, strings.ToLower(vnetID), "virtualnetworks", "vnet_id ARM 경로 형식 오류")

	assert.Equal(t, vnetName, terraform.Output(t, opts, "vnet_name"), "VNet 이름 불일치")

	assert.NotEmpty(t, terraform.Output(t, opts, "gateway_subnet_id"), "gateway_subnet_id 비어있음")
	assert.NotEmpty(t, terraform.Output(t, opts, "firewall_subnet_id"), "firewall_subnet_id 비어있음")
	assert.NotEmpty(t, terraform.Output(t, opts, "management_subnet_id"), "management_subnet_id 비어있음")

	// Azure SDK 검증: 실제 리소스 존재 확인
	assert.True(t, azure.VirtualNetworkExists(t, vnetName, rgName, subscriptionID),
		"Hub VNet이 Azure에 존재하지 않음")
	assert.True(t, azure.SubnetExists(t, "GatewaySubnet", vnetName, rgName, subscriptionID),
		"GatewaySubnet이 존재하지 않음")
	assert.True(t, azure.SubnetExists(t, "AzureFirewallSubnet", vnetName, rgName, subscriptionID),
		"AzureFirewallSubnet이 존재하지 않음")
	assert.True(t, azure.SubnetExists(t, "snet-management", vnetName, rgName, subscriptionID),
		"snet-management가 존재하지 않음")
}

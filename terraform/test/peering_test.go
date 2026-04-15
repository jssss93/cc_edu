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

func TestVNetPeering(t *testing.T) {
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionID, "ARM_SUBSCRIPTION_ID 환경변수가 필요합니다")

	uniqueID := strings.ToLower(random.UniqueId())
	hubRgName := fmt.Sprintf("rg-test-hub-peer-%s", uniqueID)
	spokeRgName := fmt.Sprintf("rg-test-spoke-peer-%s", uniqueID)
	hubVnetName := fmt.Sprintf("vnet-hub-peer-%s", uniqueID)
	spokeVnetName := fmt.Sprintf("vnet-spoke-peer-%s", uniqueID)

	opts := &terraform.Options{
		TerraformDir: "./fixtures/peering",
		EnvVars: map[string]string{
			"TF_CLI_CONFIG_FILE": "/Users/jongsu/git/js_project/cc_edu/terraform/test/test.tfrc",
		},
		Vars: map[string]interface{}{
			"subscription_id":           subscriptionID,
			"hub_resource_group_name":   hubRgName,
			"spoke_resource_group_name": spokeRgName,
			"location":                  "koreacentral",
			"hub_vnet_name":             hubVnetName,
			"spoke_vnet_name":           spokeVnetName,
			"tags": map[string]string{
				"environment": "test",
				"owner":       "terratest",
				"project":     "ccedu",
			},
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// 출력값 검증: 피어링 ID 존재 확인
	hubToSpokeID := terraform.Output(t, opts, "hub_to_spoke_peering_id")
	spokeToHubID := terraform.Output(t, opts, "spoke_to_hub_peering_id")

	assert.NotEmpty(t, hubToSpokeID, "hub_to_spoke_peering_id 비어있음")
	assert.NotEmpty(t, spokeToHubID, "spoke_to_hub_peering_id 비어있음")

	// ARM 경로에 virtualNetworkPeerings 포함 확인
	assert.Contains(t, strings.ToLower(hubToSpokeID), "virtualnetworkpeerings",
		"hub→spoke 피어링 ID 형식 오류")
	assert.Contains(t, strings.ToLower(spokeToHubID), "virtualnetworkpeerings",
		"spoke→hub 피어링 ID 형식 오류")

	// Azure SDK 검증: 양쪽 VNet 존재 확인
	assert.True(t, azure.VirtualNetworkExists(t, hubVnetName, hubRgName, subscriptionID),
		"Hub VNet이 Azure에 존재하지 않음")
	assert.True(t, azure.VirtualNetworkExists(t, spokeVnetName, spokeRgName, subscriptionID),
		"Spoke VNet이 Azure에 존재하지 않음")

	// 피어링 수 확인: 각 VNet에 피어링이 1개씩 존재해야 함
	// VirtualNetworkPropertiesFormat이 임베디드 구조체이므로 직접 접근
	hubVnet, err := azure.GetVirtualNetworkE(hubVnetName, hubRgName, subscriptionID)
	require.NoError(t, err, "Hub VNet 조회 실패")
	require.NotNil(t, hubVnet.VirtualNetworkPeerings,
		"Hub VNet 피어링 목록이 nil")
	assert.Len(t, *hubVnet.VirtualNetworkPeerings, 1,
		"Hub VNet에 피어링이 1개 있어야 함")

	spokeVnet, err := azure.GetVirtualNetworkE(spokeVnetName, spokeRgName, subscriptionID)
	require.NoError(t, err, "Spoke VNet 조회 실패")
	require.NotNil(t, spokeVnet.VirtualNetworkPeerings,
		"Spoke VNet 피어링 목록이 nil")
	assert.Len(t, *spokeVnet.VirtualNetworkPeerings, 1,
		"Spoke VNet에 피어링이 1개 있어야 함")
}

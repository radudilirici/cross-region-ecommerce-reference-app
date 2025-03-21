@description('The AKS node cluster configuration for the service API')
param aksConfig object

@description('The network configuration of the service API')
param networkConfig object

@description('The suffix to be used for the name of resources')
param resourceSuffixUID string = ''

@description('The location of the service (API) resources.')
param serviceLocation string

@description('The resource ID of the Log Analytics workspace to which the AKS cluster is connected to.')
param workspaceId string

@description('The VNet name.')
param vnetName string

@description('The AKS subnet ID.')
param aksSubnetId string

@description('The appGateway subnet ID.')
param appGatewaySubnetId string

@description('The ACR name.')
param containerRegistryName string

module appGateway './appGateway.bicep' = {
  name: 'appGateway-${serviceLocation}'
  params: {
    location: serviceLocation
    resourceSuffixUID: resourceSuffixUID
    appGatewaySubnetId: appGatewaySubnetId
    loadBalancerPrivateIp: networkConfig.loadBalancerPrivateIP
    workspaceId: workspaceId
  }
}

module externalLoadBalancerIP 'externalLoadBalancerIP.bicep' = {
  name: 'externalLoadBalancerIP-${serviceLocation}'
  params: {
    resourceSuffixUID: resourceSuffixUID
    location: serviceLocation
    workspaceId: workspaceId
  }
}

module aks './aks.bicep' = {
  name: 'aks-${serviceLocation}'
  params: {
    resourceSuffixUID: resourceSuffixUID
    location: serviceLocation
    vnetName: vnetName
    aksSubnetId: aksSubnetId
    workspaceId: workspaceId
    outboundPublicIPId: externalLoadBalancerIP.outputs.externalLoadBalancerIPId
    systemNodeCount: aksConfig.systemNodeCount
    userNodeCount: aksConfig.userNodeCount
    minUserNodeCount: aksConfig.userMinNodeCount
    maxUserNodeCount: aksConfig.userMaxNodeCount
    nodeVMSize: aksConfig.nodeVMSize
    nodeOsSKU: aksConfig.nodeOsSKU
    maxUserPodsCount: aksConfig.userMaxPodsCount
    aksAvailabilityZones: aksConfig.availabilityZones
  }
}

module rbacGrantToSharedAcr './rbacGrantToSharedAcr.bicep' = {
  name: 'rbacGrantToSharedAcr-${serviceLocation}'
  params: {
    containerRegistryName: containerRegistryName
    kubeletIdentityObjectId: aks.outputs.kubeletIdentityObjectId
  }
}

output appGatewayIP string = appGateway.outputs.publicIpAddress

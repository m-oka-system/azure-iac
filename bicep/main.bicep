param location string = resourceGroup().location

var prefix = 'bicep'
var publicSubnetName = 'public-subnet'

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }

  resource publicSubnet 'subnets' existing = {
    name: publicSubnetName
  }
}

output publicSubnetId string = vnet::publicSubnet.id

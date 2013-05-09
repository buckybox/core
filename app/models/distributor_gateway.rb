class DistributorGateway < ActiveRecord::Base
  attr_accessible :login, :password

  belongs_to :distributor
  belongs_to :gateway

  attr_encrypted :login, key: 'f96466dbaeb8ac725e2908140e743ba8519cf4bc97a87c20bc370b3a6886ee47bc7cd89afc2e709f32fc322976f4f562a6102aa1cd8affbe58f9c31b70486237'
  attr_encrypted :password, key: 'd27af93d4f32325a15628453ec61863e616e0184e2aeb87c1aadec783238794e680d3a4f7e900b38890e78a4582421833992e9101ec692f89afc1301f1fda91c'
end

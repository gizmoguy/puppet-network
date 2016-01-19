require 'facter'
require 'open-uri'
require 'timeout'
require 'ipaddr'

def is_ip?(ip)
    !!IPAddr.new(ip) rescue false
end

#Gateway
# Expected output: The ip address of the nexthop/default router
Facter.add("gateway4") do
  my_gw = nil
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
    #not all network configurations will have a nexthop.
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.match(/via\s+[^\s]+/)[0].split()[1].to_s
    end
    if is_ip?(my_gw)
      my_gw
    end
  end
end

Facter.add("gateway6") do
  my_gw = nil
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip -6 route show ::/0')
    #not all network configurations will have a nexthop.
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.match(/via\s+[^\s]+/)[0].split()[1].to_s
    end
    if is_ip?(my_gw)
      my_gw
    end
  end
end

#Primary interface
#  Expected output: The specific interface name that the node uses to communicate with the nexthop
Facter.add("primary_network4") do
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
    #not all network configurations will have a nexthop.
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.match(/via\s+[^\s]+/)[0].split()[1].to_s
      if is_ip?(my_gw)
        fun = Facter::Util::Resolution.exec("/sbin/ip route get #{my_gw}").split("\n")[0]
        fun.match(/dev\s+[^\s]+/)[0].split()[1].to_s
      end
    #some network configurations simply have a link that all interactions are abstracted through
    elsif gw_address.include? 'scope link'
      #since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      #lets just use 8.8.8.8 as far as a route goes.
      fun = Facter::Util::Resolution.exec("/sbin/ip route get 8.8.8.8").split("\n")[0]
      fun.match(/dev\s+[^\s]+/)[0].split()[1].to_s
    end
  end
end

Facter.add("primary_network6") do
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip -6 route show ::/0')
    #not all network configurations will have a nexthop.
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.match(/via\s+[^\s]+/)[0].split()[1].to_s
      if is_ip?(my_gw)
        if my_gw.start_with?('fe80:')
          gw_address.match(/dev\s+[^\s]+/)[0].split()[1].to_s
        else
          fun = Facter::Util::Resolution.exec("/sbin/ip -6 route get #{my_gw}")
          fun.match(/dev\s+[^\s]+/)[0].split()[1].to_s
        end
      end
    #some network configurations simply have a link that all interactions are abstracted through
    elsif gw_address.include? 'scope link'
      #since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      #lets just use 8.8.8.8 as far as a route goes.
      fun = Facter::Util::Resolution.exec("/sbin/ip -6 route get 2001:4860:4860::8888")
      fun.match(/dev\s+[^\s]+/)[0].split()[1].to_s
    end
  end
end

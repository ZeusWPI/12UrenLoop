#!/usr/bin/env ruby -w
require 'net/ssh'

hosts = File.open('hosts').readlines.map(&:strip)

def error(host, message)
  puts "#{Time.now}: #{host}: #{message}"
end

loop do
  hosts.each do |host|
    begin
      Timeout::timeout(5) do
        Net::SSH.start(host, 'root') do |ssh|
          usb_check = ssh.exec!("hcitool dev | grep -v Devices")
          unless usb_check.lines.count == 1
            error(host, "No Bluetooth-receiver detected (#{usb_check.strip})")
          end

          gyrid_check = ssh.exec!("ps -ewwo args | grep gyrid | grep -v grep")
          unless gyrid_check.lines.count == 1
            error(host, "Gyrid is not running (#{gyrid_check.strip})")
          end

          conn_check = ssh.exec!("netstat -t -n | tail -n +3 | tr -s ' ' | cut -d' ' -f4 | grep 9001")
          unless conn_check.lines.count == 1
            error(host, "No remote connection to port 9001 (#{conn_check.strip})")
          end

          load = ssh.exec!("cat /proc/loadavg | cut -d' ' -f2")
          if load.to_f > 1
            error(host, "High load (#{load.strip})")
          end
        end
      end
    rescue Exception => e
      error(host, e)
    end
    sleep 2

  end
  sleep 10
end

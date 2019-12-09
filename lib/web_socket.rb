require 'socket'
require 'openssl'
require 'timeout'
require 'zlib'
require 'stringio'

require "web_socket/user_agents"
require "web_socket/version"

class WebSocket
  attr_accessor :local_ip, :user_agent, :timeout, :cookie, :request, :response
  
  #-------------------------------------------------------------------------------------#
  
  def initialize(opts={})
    opts = parse_opts(opts)

    @local_ip = opts[:ip]
    @cookie = {} if opts[:cookies] == true
    @timeout = opts[:timeout]
    @user_agent = opts[:ua]
  end
  
  #-------------------------------------------------------------------------------------#

  def parse_opts(opts)
    opts = {} unless opts.is_a?(Hash)

    # defaults
    opts[:ip] = nil unless opts[:ip].is_a?(String) && opts[:ip][/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/]
    opts[:cookies] = true unless [true, false].include?(opts[:cookies])
    opts[:timeout] = 15 unless opts[:timeout].is_a?(Integer) && opts[:timeout] > 0

    # choose a random user agent
    unless opts[:ua].is_a?(String) && opts[:ua].length > 0
      opts[:ua] = USER_AGENTS[rand(USER_AGENTS.size)]
    end

    opts
  end

  #-------------------------------------------------------------------------------------#
  # combination of prepare & submit

  def fetch(host, port, method, uri, postdata=nil)
    prepare(host, method, uri, postdata)
    submit(host, port)
  end
  
  #-------------------------------------------------------------------------------------#
  
  def prepare(host, method, uri, postdata=nil)
    @request = "#{method.upcase} #{uri} HTTP/1.1\r\n" +
      "Host: #{host}\r\n" +
      "User-Agent: #{@user_agent}\r\n" +
      "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" +
      "Accept-Language: en-us,en;q=0.5\r\n" +
      "Accept-Encoding: gzip, deflate\r\n" +
      "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n" +
      "Connection: close\r\n"
    
    if @cookie.is_a?(Hash) && @cookie.size > 0
      @request += "Cookie:"
      @cookie.each_with_index do |(key, value), index|
        @request += " #{key}=#{value}"
        @request += ";" unless index == @cookie.size-1
      end
      @request += "\r\n"
    end
    
    if postdata
      @request += "Content-Type: application/x-www-form-urlencoded\r\n"
      @request += "Content-Length: #{postdata.length}\r\n\r\n" + postdata
    else
      @request += "\r\n"
    end
  end
  
  #-------------------------------------------------------------------------------------#

  def set_cookies(header)
    if @cookie.is_a?(Hash) && header.is_a?(String)
      while !(i = header.downcase.index("\r\nset-cookie:")).nil?
        header = header.slice((i+13)...header.length)
        c = header.slice(0...header.index(";")).split('=')
        @cookie[c.shift.strip] = c.join('=').strip
      end
    end
  end

  #-------------------------------------------------------------------------------------#
  
  def submit(host, port) 
    return unless @request
    socket = nil
    
    if port == 443 #ssl
      begin
        Timeout::timeout(@timeout) do
          # TCPSocket.new(remote_host, remote_port, local_host=nil, local_port=nil)
          socket = TCPSocket.new(host, port, @local_ip)
          socket = OpenSSL::SSL::SSLSocket.new(socket)
          socket.connect
        end
      rescue Timeout::Error, OpenSSL::SSL::SSLError
        return
      end
    else
      # use a nonblocking socket
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      
      # bind socket to local_ip
      socket.bind(Socket.pack_sockaddr_in(0, @local_ip)) if @local_ip
      
      begin
        socket.connect(Socket.pack_sockaddr_in(port, host))
      rescue Errno::EINPROGRESS
        # wait for a response for a number of seconds (defined by timeout)
        r = IO.select(nil, [socket], nil, @timeout)
        if r.nil? # raise Errno::ECONNREFUSED
          return
        end
      end
    end
    
    header = nil; body = nil; data = nil
    
    begin
      Timeout::timeout(@timeout) do
        # send and retrieve
        socket.print(@request)
        data = socket.read
      end
    rescue Timeout::Error
      return
    end
    
    # should at least receive a header in response
    if data && data.include?("\r\n\r\n")
      i = data.index("\r\n\r\n")
      header = data.slice(0...i).strip
      body = data.slice((i+4)..data.length).strip
    else
      header = data
    end
    
    if header && body
      # chunked? remove chunks
      if header.downcase.include?("transfer-encoding: chunked")
        body = "\r\n#{body}\r\n".gsub(/\r\n.{1,10}\r\n/, '').strip
      end
      
      # compressed via gzip? decompress
      if header.downcase.include?("content-encoding: gzip")
        begin
          body = Zlib::GzipReader.new(StringIO.new(body.strip)).read
        rescue
          body = "error: gzip decompression failed"
        end
      end
            
      # force encoding to avoid errors
      body = body.encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace, :replace => '')
    end
    
    set_cookies(header)
    @response = { header: header, body: body }
  end
  
  #-------------------------------------------------------------------------------------#
end

require "spec_helper"

describe WebSocket do
  s = WebSocket.new

  it "has a version number" do
    expect(WebSocket::VERSION).not_to be nil
  end

  context "validates options" do

    # options should always return defaults
    it "validates not hash" do
      expect( s.parse_opts(nil) ).to be_kind_of Hash
    end

    ip_match = Regexp.new(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/)

    # validates local ip format but not that ip/interface exists
    it "validates local ip" do
      expect( s.parse_opts({ip: 0})[:ip] ).to be_nil
      expect( s.parse_opts({ip: ''})[:ip] ).to be_nil
      expect( s.parse_opts({ip: '192.168.1'})[:ip] ).to be_nil
      expect( s.parse_opts({ip: '192.168.1.1'})[:ip] ).to match ip_match
      expect( s.parse_opts({ip: '127.0.0.1'})[:ip] ).to match ip_match
    end

    # defaults to true unless set = false
    it "validates use cookies" do
      expect( s.parse_opts(nil)[:cookies] ).to be true
      expect( s.parse_opts({cookies: true})[:cookies] ).to be true
      expect( s.parse_opts({cookies: false})[:cookies] ).to be false
      expect( s.parse_opts({cookies: 'true'})[:cookies] ).to be true
      expect( s.parse_opts({cookies: Array.new})[:cookies] ).to be true
    end

    # defaults to a resonable integer
    it "validates timeout" do
      expect( s.parse_opts(nil)[:timeout] ).to be > 0
      expect( s.parse_opts({timeout: nil})[:timeout] ).to be > 0
      expect( s.parse_opts({timeout: false})[:timeout] ).to be > 0
      expect( s.parse_opts({timeout: 'true'})[:timeout] ).to be > 0
      expect( s.parse_opts({timeout: 5})[:timeout] ).to eq 5
    end

    # defaults to a random
    it "validates user agent" do
      expect( s.parse_opts(nil)[:ua] ).to match /^Mozilla\//
      expect( s.parse_opts({ua: false})[:ua] ).to match /^Mozilla\//
      expect( s.parse_opts({ua: nil})[:ua] ).to match /^Mozilla\//
      expect( s.parse_opts({ua: 5})[:ua] ).to match /^Mozilla\//
      expect( s.parse_opts({ua: 'Googlebot 1.2.3'})[:ua] ).to eq 'Googlebot 1.2.3'
    end

  end

  context "fetches www.google.com" do

    it "using http port 80" do
      s.fetch('www.google.com', 80, 'get', '/')
      expect( s.response[:header] ).to include "Set-Cookie: NID"
    end

    it "using https port 443" do
      s.fetch('www.google.com', 443, 'get', '/')
      expect( s.response[:header] ).to include "\r\nSet-Cookie: NID"
      expect( s.response[:body] ).to include "<title>Google</title>"
    end
    
  end

end

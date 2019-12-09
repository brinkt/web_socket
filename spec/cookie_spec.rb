require "spec_helper"

google_redirect_header = %{
HTTP/1.1 302 Found\r
Location: https://www.google.com/?gws_rd=ssl\r
Cache-Control: private\r
Content-Type: text/html; charset=UTF-8\r
Server: gws\r
Content-Length: 231\r
X-XSS-Protection: 1; mode=block\r
X-Frame-Options: SAMEORIGIN\r
Set-Cookie: NID=91=Dumha4mQACTz_KqZQzZhxrW0hjsjSVlXzQ; path=/; domain=.google.com; HttpOnly\r
Connection: close
}

facebook_header = %{
HTTP/1.1 200 OK\r
X-Frame-Options: DENY\r
X-XSS-Protection: 0\r
Pragma: no-cache\r
X-UA-Compatible: IE=edge,chrome=1\r
Cache-Control: private, no-cache, no-store, must-revalidate\r
Set-Cookie: fr=0PJuLF2eiNZrmxGWI..BYNjdL.ro.AAA.0.0.BYNjdL.AWUQXjXU; path=/; domain=.facebook.com; httponly\r
Set-Cookie: datr=zSg2WPSmz5Ol7PuNv_Iz2-8E; path=/; domain=.facebook.com; httponly\r
Content-Encoding: gzip\r
Content-Type: text/html\r
Connection: close
}

describe WebSocket do
  s = WebSocket.new

  context "single cookie" do
    s.set_cookies(google_redirect_header)

    it "should parse" do
      expect( s.cookie ).to be_kind_of Hash
      expect( s.cookie ).to include 'NID'
      expect( s.cookie['NID'] ).to eq '91=Dumha4mQACTz_KqZQzZhxrW0hjsjSVlXzQ'
    end

  end

  context "multiple cookies" do
    s.set_cookies(facebook_header)

    it "should parse" do
      expect( s.cookie ).to be_kind_of Hash
      expect( s.cookie ).to include 'fr'
      expect( s.cookie['fr'] ).to eq '0PJuLF2eiNZrmxGWI..BYNjdL.ro.AAA.0.0.BYNjdL.AWUQXjXU'
      expect( s.cookie ).to include 'datr'
      expect( s.cookie['datr'] ).to eq 'zSg2WPSmz5Ol7PuNv_Iz2-8E'
    end

  end

end

use Rack::Static,
  :urls => ["/images", "/js", "/css"],
  :root => "public"


use Rack::Static, :urls => { "/a-maxvoltar-special.css" => "a-maxvoltar-special.css" }
use Rack::Static, :urls => {"/" => 'result-0704.html'}
use Rack::Static, :urls => {"/all" => 'result-all-0704.html'}

run lambda { |env|
  [
    404,
    {
      'Content-Type'  => 'text/html',
      'Cache-Control' => 'public, max-age=86400'
    },
    StringIO.new("<html>Bob Stinkt</html>")
  ]
}

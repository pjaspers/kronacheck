
use Rack::Static, :urls => { "/a-maxvoltar-special.css" => "a-maxvoltar-special.css" }
use Rack::Static, :urls => { "/a-maxvoltar-special.css.map" => "a-maxvoltar-special.css.map" }
use Rack::Static, :urls => {"/" => 'today-all.html'}
use Rack::Static, :urls => {"/tpp" => 'today-twitterpp.html'}

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

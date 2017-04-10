# A puppet class that always passes
class passing {
  file { "/tmp/passed":
    ensure => file,
    owner  => "root",
    group  => "root",
    mode   => "0644",
  }
}

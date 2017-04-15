# Another puppet class that always passes
class passing::class2 {
  file { "/tmp/class2":
    ensure => file,
    owner  => "root",
    group  => "root",
    mode   => "0644",
  }
}

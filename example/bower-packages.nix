{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "angular" "1.5.3" "~1.5.0" "1749xb0firxdra4rzadm4q9x90v6pzkbd7xmcyjk6qfza09ykk9y")
  (fetchbower "bootstrap" "3.3.6" "~3.3.6" "1vvqlpbfcy0k5pncfjaiskj3y6scwifxygfqnw393sjfxiviwmbv")
  (fetchbower "jquery" "2.2.2" "1.9.1 - 2" "10sp5h98sqwk90y4k6hbdviwqzvzwqf47r3r51pakch5ii2y7js1")
]; }

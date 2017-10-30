{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "angular" "1.4.12" "~1.4.0" "06kig230y46xix7s43w2hc5ig3vyy7c47whhpxr1hqml0k8baybq")
  (fetchbower "angular-animate" "1.4.12" "~1.4.0" "18im4z82nk6g54pmk9y99n1x5ha01ln24vk2s48fl4lnkpkb0z53")
  (fetchbower "angular-cookies" "1.4.12" "~1.4.0" "19jj1wiwwfdjnwk1lm3y43z0c3v13wldk00ypwb370gbp45rxahx")
  (fetchbower "angular-touch" "1.4.12" "~1.4.0" "0bqkjsvr84px5ylxkfmkmsj7qv21qjw4c6xmi9jq1da0l7041ykh")
  (fetchbower "angular-sanitize" "1.4.12" "~1.4.0" "0yv300rf245hzmqnfj879qm07ffnkc8zrnqd1yfxpc6sj4y7rh3n")
  (fetchbower "angular-ui-router" "0.2.18" "~0.2.15" "077ba0kspjzdlkvl1ixh81hzf2ppgiilj31r8jimycpaqkl42lbk")
  (fetchbower "bootstrap" "3.3.7" "~3.3.4" "1dp3h37j81n10csjz7sxnjx1crfj14sngrwmp1ss095501b10456")
  (fetchbower "angular-bootstrap" "0.11.2" "~0.11.2" "130s1n0mi790r1xha38hjzdwcscjl8kqjbp695n8i2k7yh12xv4y")
  (fetchbower "moment" "2.10.6" "~2.10.3" "05lly0jgbssa5a9xh768jhln5qwyiivhm5fyx707af3bpwyky111")
  (fetchbower "lodash" "3.9.3" "~3.9.3" "12c34ah0nnhflg0wa50cbwq1jfwizh8rviqd7i0hbfipbancsy79")
  (fetchbower "backbone" "components/backbone#1.2.0" "components/backbone#~1.2" "1arcv99907bzr84lfrm9qyv0l8al653p6m4ih188n2dz8dd7n6ls")
  (fetchbower "jquery" "3.1.0" "1.9.1 - 3" "08qzyi6dvin5rwqy4lnsh9akh863n8cvn1jsgbh6906wmjlb3nhj")
  (fetchbower "underscore" "1.8.3" "*" "0bs4aj6i1s03z8sl8pvwldslvwzdnhf4k93hn9kc6c3qlzkssa69")
]; }

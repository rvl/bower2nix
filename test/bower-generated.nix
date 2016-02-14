{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "angular" "1.4.9" "~1.4.0" "0a2754zsxv9dngpg08gkr9fdwv75y986av12q4drf1sm8p8cj6bs")
  (fetchbower "angular-animate" "1.4.9" "~1.4.0" "0xwy6y8zgbq07ikvld4s9ypdd41kam1q47f3zlxmv8v724k8gh16")
  (fetchbower "angular-cookies" "1.4.9" "~1.4.0" "03c0fp09jpbxxng3rfn36flz3ivb09ypsvf858w0qvrs0n1z9vvw")
  (fetchbower "angular-touch" "1.4.9" "~1.4.0" "0kch1hgrz2xy07zg3jyn5g352wm6qpgpwaal2977w666bpb8d1vw")
  (fetchbower "angular-sanitize" "1.4.9" "~1.4.0" "0zn2fwam6qkgfh994wqjgwb7j8876g2gbxmihl94fdibq4zihpxv")
  (fetchbower "angular-ui-router" "0.2.18" "~0.2.15" "0dldz4mn1zjrm5dxcmh1m4l940ykavka3y7x8s0pvankf7k8f671")
  (fetchbower "bootstrap" "3.3.6" "~3.3.4" "025z7zwihx8vgkmz0af442jypvifl30gcry5yjd12isqh66mb402")
  (fetchbower "angular-bootstrap" "0.11.2" "~0.11.2" "0gqnnkpal3dcn4zzgz72p8mj9f3vqz6lx3xvbswl1mx8imaykbq2")
  (fetchbower "moment" "2.10.6" "~2.10.3" "16l0byri8ddx5shcpn7a8vfqppbsm69ih5kqpra1zqk9g3glkm6m")
  (fetchbower "lodash" "3.9.3" "~3.9.3" "0bgl7758jlh2fdv9v3yfhspsnfn3qjymlh856ybps5c2pl8n50q0")
  (fetchbower "jquery" "2.2.0" "1.9.1 - 2" "0r6gyjrh242a9r7g8c28wffjzgbsx8gf81scj8dh31jp5ii1yqpm")
]; }

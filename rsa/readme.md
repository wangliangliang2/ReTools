### 证书编译【RSA】：

```powershell
 openssl genrsa -out private_key.pem 1024 //私钥
 openssl rsa -in private_key.pem -out rsa_public_key.pem -pubout //公钥
 openssl req -new -key private_key.pem -out rsaCertReq.csr
 openssl x509 -req -days 3650 -in rsaCertReq.csr -signkey private_key.pem -out rsaCert.crt
 openssl x509 -outform der -in rsaCert.crt -out public_key.der //苹果系列可用的RSA der
 openssl pkcs12 -export -out private_key.p12 -inkey private_key.pem -in rsaCert.crt //苹果系列可用的RSA p12私钥
 openssl pkcs8 -topk8 -in private_key.pem -out pkcs8_private_key.pem -nocrypt //JAVA 可用私钥
 
 //以下是说明文档:
  --x509:https://en.wikipedia.org/wiki/X.509
 --pkcs12:https://en.wikipedia.org/wiki/PKCS_12
```


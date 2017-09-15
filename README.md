# cert creator

Creates a CA and signs a certificate with this CA for multiple domain names or ips

# usage

    ./create-certs.sh <domain1> [<domain2> <domain3> ...] [<ip1> <ip2> ...]

# result

The script creates three files in the current directory:

    ca.pem        # the ca certificate
    cert.pem      # the certificate that was signed by the ca
    key.pem       # the private key for cert.pem

# why?

I needed this for consul and vault, where

 - `ca.pem` -> `ca_file` in consul / `tls_ca_file` in vault
 - `cert.pem` -> `cert_file` in consul / `tls_cert_file` in vault
 - `key.pem` -> `key_file` in consul / `tls_key_file` in vault

# example

<pre>
./create-certs.sh example.com foo.example.com 10.10.1.1 hello.com *foo.com

$ openssl x509 -noout -text -in cert.pem
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 10 (0xa)
        Signature Algorithm: sha1WithRSAEncryption
        <b>Issuer: CN=example.com</b>
        Validity
            Not Before: Sep 15 14:18:12 2017 GMT
            Not After : Sep 13 14:18:12 2027 GMT
        Subject: CN=example.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (2048 bit)
                Modulus (2048 bit):
                ...
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            X509v3 Key Usage:
                Digital Signature, Non Repudiation, Key Encipherment
            X509v3 Subject Alternative Name:
                <b>DNS:foo.example.com, IP Address:10.10.1.1, DNS:hello.com, DNS:*foo.com</b>
    Signature Algorithm: sha1WithRSAEncryption
       ...
</pre>

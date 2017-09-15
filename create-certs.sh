#!/bin/bash -e
# https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04

main_subject=${1:?usage: $0 <domain1> [<domain2> ...] [<ip1> ...]}
shift
alternative_subjects=""

dns_cnt=1
ip_cnt=1
while [ -n "$1" ]
do
  if echo "$1" | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$"
  then
    alternative_subjects="${alternative_subjects}
IP.${ip_cnt} = $1"
    let ip_cnt++
  else
    alternative_subjects="${alternative_subjects}
DNS.${dns_cnt} = $1"
    let dns_cnt++
  fi
  shift
done

base=${PWD}

mkdir -p ${base}/ssl/CA
chmod 0700 ${base}/ssl/CA

(
cd ${base}/ssl/CA
echo "000a" > serial
touch certindex

# create ca cert
openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -out ca.crt -subj "/CN=${main_subject}/"

# create wildcart cert
openssl req -newkey rsa:2048 -nodes -out ${main_subject}.csr -keyout ${main_subject}.key -subj "/CN=${main_subject}/" -config <(cat<<EOF
[ dn ]
[req]
distinguished_name = dn

$(test -z "${alternative_subjects}" || {
  cat<<INNER_EOF
req_extensions = v3_req
[ v3_req ]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[ alt_names ]
${alternative_subjects}
INNER_EOF
})

EOF
)

openssl ca -batch -notext -extensions v3_req -in ${main_subject}.csr -out ${main_subject}.crt -config <(cat<<EOF
[ ca ]
default_ca = dummy_ca

[ dummy_ca ]
unique_subject = no
new_certs_dir = .
certificate = ca.crt
database = certindex
private_key = privkey.pem
serial = serial
default_days = 3650
default_md = sha1
policy = dummy_ca_policy
x509_extensions = dummy_ca_extensions

[ dummy_ca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = optional
emailAddress = optional
organizationName = optional
organizationalUnitName = optional

[ dummy_ca_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth,clientAuth

$(test -z "${alternative_subjects}" || {
  cat<<INNER_EOF
req_extensions = v3_req
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
${alternative_subjects}
INNER_EOF
})

EOF
)
)

(set -x;
cp ssl/CA/ca.crt ca.pem
cp ssl/CA/${main_subject}.crt cert.pem
cp ssl/CA/${main_subject}.key key.pem
)

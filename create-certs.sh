#!/bin/bash

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

cat > csr_details.txt <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
$(if [ -n "${alternative_subjects}" ]
then
  echo "req_extensions = v3_req"
fi)
distinguished_name = dn

[ dn ]
C=DE
ST=Berlin
OU=Secret Domain
emailAddress=admin@${main_subject}
CN = ${main_subject}

$(if [ -n "${alternative_subjects}" ]
then
  cat<<INNER_EOF
[ v3_req ]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[ alt_names ]
${alternative_subjects}
INNER_EOF
fi
)
EOF

if [ ! -e ca_cert.pem ]
then
  openssl req -new -x509 -days 3650 -keyout ca_key.pem -out ca_cert.pem -config <(cat<<EOF
countryName_default = DE
stateOrProvinceName_default = Berlin
localityName_default = Berlin
distinguished_name = dn
output_password = xxxx
prompt = no

[ dn ]
C=DE
ST=Berlin
OU=Secret Domain
emailAddress=admin@
CN = xxx.yyy.zzz

EOF
  )

  mkdir certs
  echo "01" > serial
  touch index.txt
fi


# Let's call openssl now by piping the newly created file in
openssl req -new -sha256 -nodes -out ${main_subject}.csr -newkey rsa:2048 -keyout ${main_subject}.key -config csr_details.txt
openssl ca -keyfile ca_key.pem -outdir . -verbose -cert ca_cert.pem -in ${main_subject}.csr -out ${main_subject}.pem -config <(cat << EOF
[ca]
default_ca = CA_default    # The default ca section

[ CA_default ]
dir      = certs            # Where everything is kept
certs    = \$dir/certs      # Where the issued certs are kepp
crl_dir  = \$dir/crl        # Where the issued crl are kept
database = index.txt  # database index file.
serial   = serial

default_md  = sha1

default_days  = 365   # how long to certify for
default_crl_days= 30  # how long before next CRL
default_md  = sha1    # which md to use.
preserve  = no        # keep passed DN ordering

policy    = policy_anything

[ policy_anything ]
countryName   = optional
stateOrProvinceName = optional
localityName    = optional
organizationName  = optional
organizationalUnitName  = optional
commonName    = supplied
emailAddress    = optional
EOF
)

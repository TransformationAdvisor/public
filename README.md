## Verify Transformation Advisor Images

### Pre-req

Install `Skopeo` tool. Please use version 0.1.40+ and non-dev version.

   1 For Redhat 8:

        1. Download: ftp://ftp3.linux.ibm.com/redhat/ibm-yum-rhel8.sh with FTP3 account, and run it on the Redhat 8 server
        2. run `dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm`
        3. run `dnf upgrade`
        4. run `dnf install skopeo`
        5. exit the redhat server and re-login a new session, to enable skopeo

   2 For Ubuntu 16:

        sudo apt-add-repository ppa:projectatomic/ppa -y
        sudo apt-get update -y
        sudo apt-get install skopeo -y

### Steps to verify

1. Pull docker images from docker hub, e.g.

        # pull down the test image
        docker pull ibmcom/icp-transformation-advisor-ui:sample-image-signing-eabde5e

2. Copy from local docker repo to a location:

        # the location where you want to copy the image to
        mkdir -p /Users/ibm/Downloads/transformation-advisor/docker

        skopeo copy --dest-tls-verify=false \
        docker-daemon:docker.io/ibmcom/icp-transformation-advisor-ui:sample-image-signing-eabde5e \
        dir:/Users/ibm/Downloads/transformation-advisor/docker

3. Download the signature, keys and certs from this repo

        # signature of the image ibmcom/icp-transformation-advisor-ui:sample-image-signing-eabde5e is located below:
        https://github.com/TransformationAdvisor/public/tree/master/sample/signature-sample-eabde5e

        The signature is used to verify the image

        # keys and certs
        tasigningcert-public.gpg: public key is used to to verify signature
        tasigningcert.pem: certificate is used to to verify public key
        tasigningcert-chain0.pem: certificate chain 0 is used to verify certificate validity, hosted on www.digicert.com

4. Import public key

        # import
        gpg2 --import tasigningcert-public.gpg

        # verify
        gpg2 -k --fingerprint

        -----------------------------
        pub   rsa2048 2020-04-22 [SCEA]
              7D91 08FA F552 72DC F922  EE16 50C2 D9CF F1A2 F295
        uid           [ unknown] tasigningcert

5. Verify the cert

        openssl x509 -text -in tasigningcert.pem

        Signature Algorithm: sha256WithRSAEncryption
            Issuer: C=US, O=DigiCert Inc, OU=www.digicert.com, CN=DigiCert SHA2 Assured ID Code Signing CA
            Validity
                Not Before: Apr 22 00:00:00 2020 GMT
                Not After : Apr 27 12:00:00 2022 GMT
            Subject: C=US, ST=New York, L=Armonk, O=International Business Machines Corporation, OU=IBM CCSS, CN=International Business Machines Corporation

6. Verify the image with signature

        # location of the manifest.json: /Users/ibm/Downloads/transformation-advisor/docker/manifest.json
        # docker reference: transformation-advisor 
        # The same docker reference is used for all the images
        # the imported public key fingerprint: 7D9108FAF55272DCF922EE1650C2D9CFF1A2F295
        # the downloaded singature: /Users/ibm/Downloads/signature-sample-eabde5e
      
        skopeo standalone-verify \
        /Users/ibm/Downloads/transformation-advisor/docker/manifest.json \
        transformation-advisor \
        7D9108FAF55272DCF922EE1650C2D9CFF1A2F295 \
        /Users/ibm/Downloads/signature-sample-eabde5e

        Signature verified, digest sha256:c84367ae8593c428d8174ed33097e31518169ac94e5cc03742ef1ff78d94bd5f

7. Verify the signature with keys and certs

        openssl ocsp -no_nonce \
        -issuer /Users/ibm/Downloads/tasigningcert-chain0.pem \
        -cert /Users/ibm/Downloads/tasigningcert.pem \
        -VAfile /Users/ibm/Downloads/tasigningcert-chain0.pem \
        -text -url http://ocsp.digicert.com \
        -respout ocsptest
        
        ...
        Response verify OK
        /Users/ibm/Downloads/tasigningcert.pem: good
        	This Update: Jun 16 07:57:34 2020 GMT
        	Next Update: Jun 23 07:12:34 2020 GMT
         
### For Customers Using IBM Entitled Registry

You can setup verification automatic for the AMD64 image:

1. add a policy for the icr registry in /etc/containers/policy.json and include the public key
  ```
  {
    "default": [
      {
        "type": "insecureAcceptAnything"
      }
    ],
    "transports": {
      "docker-daemon": {
        "": [
          {
            "type": "insecureAcceptAnything"
          }
        ]
      },
      "docker": {
        "cp.stg.icr.io": [
          {
            "type": "signedBy",
            "keyType": "GPGKeys",
            "keyPath": "/root/tasigningcert-public.gpg"
          }
        ]
      }
    }
  }
  ```
2. use `skopeo` to pull the image to a local machine. If the image is not signed, it will fail. e.g if pulling transadv-operator:2.2.0 will fail since it is not signed
  ```
  skopeo copy --remove-signatures --src-creds iamapikey:${password} \
               docker://cp.stg.icr.io/cp/icpa/transadv-operator:2.3.0-test \
               docker-daemon:cp.stg.icr.io/cp/icpa/transadv-operator:2.3.0-test
  ```
  ```
  root@doggish1:~# skopeo copy --remove-signatures --src-creds iamapikey:${password}docker://cp.stg.icr.io/cp/icpa/transadv-operator:2.3.0-test docker-daemon:cp.stg.icr.io/cp/icpa/transadv-operator:2.3.0-test 
  Copying blob 631ae23e2389 done
  Copying blob d4aa4753891a done
  Copying blob 68a459654aba done
  Copying blob 08d2a786ba43 done
  Copying blob b6d3b7b04ffd done
  Copying blob f6e4f72587af done
  Copying blob e5cd6367520c done
  Copying blob d4b9d95aabd7 done
  Copying blob 60dce98f5b89 done
  Copying config 08f3e238a7 done
  Writing manifest to image destination
  Storing signatures
  root@doggish1:~#
  ```
  For example, you will get an error if try to pull transadv-operator:2.2.0
  ```
  @doggish1:~# skopeo copy --remove-signatures --src-creds iamapikey:${password} docker://cp.stg.icr.io/cp/icpa/transadv-operator:2.2.0 docker-daemon:cp.stg.icr.io/cp/icpa/transadv-operator:2.2.0 
  FATA[0001] Source image rejected: A signature was required, but no signature exists 
  root@doggish1:~#
  ```

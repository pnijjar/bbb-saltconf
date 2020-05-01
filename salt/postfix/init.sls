postfix-pkg:
  pkg.installed:
    - name: postfix
 

postfix-service:
  service.running:
    - name: postfix

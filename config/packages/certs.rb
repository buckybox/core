package :gpg do
  apt :gnupg

  verify do
    has_apt :gnupg
  end
end

package :certs do
  requires :gpg
  
  certs_local = File.join(File.dirname(__FILE__), 'configs', 'certs', Package.stage, 'certs.tar.gzip.gpg')
  certs_remote = "/etc/ssl/certs/"
  tmp_file = "/tmp/certs.tar.gzip.gpg"
  key_name = Package.stage == 'production' ? 'my_buckybox_com-2013-july' : 'staging_buckybox_com'
  cert_name = Package.stage == 'production' ? 'ssl-bundle-2013-july.crt' : 'ssl-bundle.crt'

  transfer certs_local, tmp_file do
    post :install, "mv #{tmp_file} #{certs_remote}"
  end

  noop do
    post :install, lambda{Capistrano::CLI.ui.ask("Please log into the server and decrypt #{certs_remote}certs.tar.gzip.gpg with this command 'sudo gpg #{certs_remote}certs.tar.gzip.gpg' then continue here. (Press enter)"); "echo noop"}
    post :install, "tar -zxf #{certs_remote}certs.tar.gzip -C #{certs_remote}"
    post :install, "cp #{certs_remote}#{key_name}.key /etc/ssl/private/"
  end

  verify do
    has_file "#{certs_remote}#{cert_name}"
    has_file "/etc/ssl/private/#{key_name}.key"
  end

end

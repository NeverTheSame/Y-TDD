resource "aws_instance" "veeam_server" {
  count         = 10 # создал 10 независимых серверов Veeam
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"
  key_name      = "aws-key"
  subnet_id     = "subnet-name"

  tags = {
    Name = "Veeam-Server-${count.index + 1}"
    Role = "BackupPrimary"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -Command \"Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force\"",
      "powershell.exe -Command \"winrm quickconfig -q\""
    ]
    connection {
      type     = "winrm"
      user     = "Administrator"
      password = var.admin_password
      host     = self.public_ip
    }
  }

  # provisioner будет запускать Ansible плейбук на КАЖДОМ из 10 инстансов
  # передаю только IP текущего инстанса в инвентарь Ansible
  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' --user Administrator --extra-vars 'ansible_password=${var.admin_password}' ./install_veeam.yml"
  }
}
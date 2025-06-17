resource "aws_instance" "veeam_server" {
  count         = 10 # создал 10 серверов для параллельного бэкапа
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"
  key_name      = "aws-key"
  subnet_id     = "subnet-name"

  tags = {
    Name = "Veeam-Server-${count.index + 1}"
    Role = "Backup"
  }

  # использовал provisioner для вызова Ansible после создания инстанса
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

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' --user Administrator --extra-vars 'ansible_password=${var.admin_password}' ./install_veeam.yml"
  }
}
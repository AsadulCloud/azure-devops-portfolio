# apache2

An Ansible role that installs and configures the Apache2 web server on Ubuntu/Debian systems.

## Requirements

- Target hosts must be running Ubuntu or Debian
- Python must be installed on target hosts (required by Ansible)
- SSH access to target hosts

## Role Variables

Variables are defined in `defaults/main.yml` and can be overridden:

| Variable | Default | Description |
|---|---|---|
| `apache2_port` | `80` | Port Apache listens on |
| `apache2_doc_root` | `/var/www/html` | Document root directory |

## Dependencies

None.

## Example Playbook

```yaml
- hosts: webservers
  become: true
  roles:
    - role: apache2
```

## What This Role Does

1. Installs Apache2 package
2. Deploys a custom `index.html` via the `files/` directory
3. Ensures the Apache2 service is started and enabled on boot
4. Uses handlers to restart Apache2 when configuration changes

## License

MIT

## Author

**Md Asadul Howlader**  
Cloud & DevOps Engineer (Azure)  
GitHub: [AsadulCloud](https://github.com/AsadulCloud)

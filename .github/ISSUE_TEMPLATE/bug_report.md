---
name: Bug report
about: Create a bug report
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behaviour:

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behaviour**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**OS (please complete the following information):**

- OS: [e.g. Ubuntu, Debian, CentOS]
- Installation: [panel or wings]

- type: textarea
  id: logs
  attributes:
    label: pterodactyl-installer logs
    description: |
      Run the following command to collect logs on your system.
      
      `cat /var/log/pterodactyl-installer.log | nc bin.ptdl.co 99`
    placeholder: "https://bin.ptdl.co/a1h6z"
    render: bash
  validations:
    required: false

**Additional context**
Add any other context about the problem here.

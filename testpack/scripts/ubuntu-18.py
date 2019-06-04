#!/usr/bin/env python3

import unittest
from testpack_helper_library.unittests.dockertests import Test1and1Common


class TestUbuntu18(Test1and1Common):

    def assertPackageIsInstalled(self, packageName):
        op = self.exec("dpkg -l %s" % packageName)
        self.assertTrue(
            op.find(packageName) > -1,
            msg="%s package not installed" % packageName
        )

    # <tests to run>

    def test_docker_logs(self):
        expected_log_lines = [
            "Executing hook /hooks/entrypoint-pre.d/01_ssmtp_setup",
            "Executing hook /hooks/entrypoint-pre.d/02_user_group_setup",
            "Executing hook /hooks/supervisord-pre.d/20_configurability"
        ]
        container_logs = self.logs()
        for expected_log_line in expected_log_lines:
            self.assertTrue(
                container_logs.find(expected_log_line) > -1,
                msg="Docker log line missing: %s from (%s)" % (expected_log_line, container_logs)
            )

    def test_OS(self):
        lines = self.exec("cat /etc/lsb-release")
        for line in lines.split('\n'):
            if line.find("DISTRIB_RELEASE") > -1:
                self.assertEqual('DISTRIB_RELEASE=18.04', line)
                break

    def test_id(self):
        self.assertEqual("10000", self.exec("whoami").strip())

    def test_supervisor(self):
        self.assertPackageIsInstalled("supervisor")

        self.assertTrue(
            self.exec("ps -ef").find('supervisord') > -1,
            msg="supervisord not running"
        )

        sv_log = self.exec("ls -ld /var/log/supervisor")
        self.assertFalse(
            sv_log.find("No such file or directory") > -1,
            msg="/var/log/supervisor is missing"
        )
        self.assertEqual(
            sv_log[8], 'w',
            msg="/var/log/supervisor is not a writable by others"
        )

        self.assertFalse(
            self.exec("ls -l /etc/supervisor/supervisord.conf").find("No such file or directory") > -1,
            msg="/etc/supervisor/supervisord.conf is missing"
        )

    def test_vim(self):
        self.assertPackageIsInstalled("vim")

    def test_curl(self):
        self.assertPackageIsInstalled("curl")

    def test_bzip2(self):
        self.assertPackageIsInstalled("bzip2")

    def test_apt(self):
        self.assertTrue(
            self.exec("ls -l /var/lib/apt/lists").find("total 0") > -1,
            msg="/var/lib/apt/lists should be empty"
        )

    # </tests to run>

if __name__ == '__main__':
    unittest.main(verbosity=1)

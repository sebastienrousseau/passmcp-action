# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# What `make coverage` measures: the scripts, every one of them, whether a
# test ran it or not. The tests, the tracing shims and the curl stub are
# not the product. bashcov calls SimpleCov.start itself; this file only
# configures it.

SimpleCov.configure do
  cover "scripts/*.sh"
  skip "/tests/"
end

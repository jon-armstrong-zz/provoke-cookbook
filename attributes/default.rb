# The MIT License (MIT)
#
# Copyright (c) 2014 Ian Good
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

default['provoke'].tap do |provoke|

  provoke['install-python-packages'] = true

  provoke['default-amqp-timeout'] = 10
  provoke['default-mysql-timeout'] = 10

  provoke['uwsgi-defaults`'].tap do |uwsgi|
    uwsgi['master'] = true
    uwsgi['master-as-root'] = true
    uwsgi['buffer-size'] = 32768
    uwsgi['max-fd'] = 65535
    uwsgi['log-reopen'] = true
    uwsgi['need-app'] = true
  end

  provoke['worker-defaults'].tap do |worker|
    worker['max-fd'] = 65535
  end

end


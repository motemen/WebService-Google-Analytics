use inc::Module::Install;
name 'WebService-Google-Analytics';
all_from 'lib/WebService/Google/Analytics.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;

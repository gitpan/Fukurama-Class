#!perl -T
use Test::More tests => 21;
use strict;
use warnings;

use CGI();
use Fukurama::Class();

BEGIN {
	$Fukurama::Class::Rigid::PACKAGE_NAME_CHECK = 0;
};


eval("use Fukurama::Class( 1, 2, 3 )");
like($@, qr/uneven/i, 'deny uneven parameter');
eval("use Fukurama::Class( 1, 2, 1, 3 )");
like($@, qr/twice/i, 'deny twice option-keys');
eval("use Fukurama::Class( 1, 2 )");
like($@, qr/not allowed/i, 'deny not allowed parameter');
eval("use Fukurama::Class( version => 'a' )");
like($@, qr/value.*version.*not allowed/i, 'croak at not allowed or incorrect value-type');
eval("use Fukurama::Class( extends => 'MyTestClass' )");
like($@, qr/value.*extends.*not allowed/i, 'croak at an unloaded class');
eval("use Fukurama::Class( extends => '' )");
is($@, '', 'can have no parent');
eval("use Fukurama::Class( implements => [] )");
is($@, '', 'can have no interface');
eval("use Fukurama::Class( implements => ['MyInterface', 'MySecondItf'] )");
like($@, qr/value.*MyInterface.*MySecondItf.*implements.*not allowed/i, 'croak at wrong interface');

{
	package MyVersion;
	eval("use Fukurama::Class( version => 1.5 )");
	main::is($@, '', 'accept versions');
	main::is($MyVersion::VERSION, 1.5, 'version works');
}

{
	package MyExtends;
	eval("use Fukurama::Class( extends => 'CGI' )");
	main::is($@, '', 'accept extends');
	main::is(join(', ', @MyExtends::ISA), 'CGI', 'extends works');
}
{
	package MyImplements;
	sub new {}
}
{
	package MyInterface;
	use Fukurama::Class( implements => 'MyVersion' );
	use Fukurama::Class( implements => ['MyVersion', 'MyImplements'] );
	main::is($@, '', 'accept implements');
	main::is(join(', ', @MyInterface::ISA), '', 'no ISA pollution');
	main::is(UNIVERSAL::isa('MyInterface', 'MyVersion'), 1, 'implements works as single');
	main::is(UNIVERSAL::isa('MyInterface', 'MyImplements'), 1, 'implements works as list');
	main::is(MyInterface->isa('MyImplements'), 1, 'isa is overwritten');
	sub new : Method(|int|) {}
}
{
	package MyAbstract;
	use Fukurama::Class;
	sub new : Method(|int|){}
	eval("use Fukurama::Class( abstract => 1 );Fukurama::Class::Abstract->run_check()");
	main::is($@, '', 'abstract works');
	eval("MyAbstract->new()");
	main::like($@, qr/abstract class/i, 'abstract croak at runtime');
}
{
	package MyAttributes;
	use base 'MyAbstract';
	no strict;
	sub new : Method(|int|) { 1 }
}
is(MyAttributes->new(), 1, 'abstract method called by child');
{
	package MyFullUsage;
	use Fukurama::Class( extends => 'MyAbstract', implements => 'MyImplements', version => 1.10, abstract => 1 );
	sub new : Method(|int|) {}
}
eval {
	MyFullUsage->new();
};
like($@, qr/Abstract class/, 'calling abstract class');
{
	package MyChild;
	use base 'MyFullUsage';
	sub new : Method(|int|) {}
}

#!/usr/bin/perl

use strict;
use warnings;

my $view="score";








sub readFile
{
	my $file = shift;
	open(DATA, '<', "$file") || die("can't open datafile: $!\n");
	my @data = <DATA>;
	chomp(@data);
	return uc(join("", @data));
}

sub delta
{
	my $j = shift;
	my $i = shift;
	if ((($i eq 'A') && ($j eq 'U')) || (($i eq 'U') && ($j eq 'A')))
	{
		return 1;
	}
	if ((($i eq 'G') && ($j eq 'C')) || (($i eq 'C') && ($j eq 'G')))
	{
		return 1;
	}
#	if ((($i eq 'G') && ($j eq 'U')) || (($j eq 'U') && ($i eq 'G')))
#	{
#		return 1;
#	}
	return 0;
}


sub fill_array
{
	my $field = shift;
	my $size  = shift;
	my $sequence = shift;

	for (my $j = 1 ; $j< $size ; $j++)
	{	
		for (my $x = $j ; $x < $size; $x++)
		{
			my $resultHash = &gamma($sequence,$field,$x,$x-$j);
			$field->[$x][$x-$j] = $resultHash;
			
			
			$field->[$x][$x-$j]{jcoord} = $x;
			$field->[$x][$x-$j]{icoord} = $x-$j;
		}
	}
}


sub gamma
{
	my $sequence = shift;
	my $field = shift;
	my $j     = shift;
	my $i     = shift;
	my @results;
	my $max;

	my %diag = ( score => $field->[$j - 1][$i + 1]{score}  + &delta(substr($sequence,$j,1),substr($sequence,$i,1)), ptr => "d");
	my %left = ( score => $field->[$j - 1][$i    ]{score}, ptr => "l");
	my %up   = ( score => $field->[$j    ][$i + 1]{score}, ptr => "u");

	
	my %bifork = ( score => 0, ptr => "b", k => 0);
	my $ktemp = 0;
	for (my $k=$i+1; $k<$j; $k++)
	{
		$ktemp=$field->[$k][$i]{score} + $field->[$j][$k+1]{score};
		if($ktemp > $bifork{score})
		{
			$bifork{score}=$ktemp;
			$bifork{k}=$k;
		}
	}

	push(@results,\%diag);
	push(@results,\%bifork);
	push(@results,\%up);
	push(@results,\%left);

	$max = (sort { $a->{score} <=> $b->{score}  }  (@results))[-1];    

	return $max;
}

sub traceback
{
	my $field = shift;
	my $sequence = shift;
	my $leftresult="";
	my $rightresult="";
	my @stack = ();
	push(@stack,$field->[length($sequence)-1][0]);	


	while(scalar(@stack)>0)
	{
		my %actual = %{pop(@stack)};
		
		#print("$actual{jcoord} $actual{icoord}\n");
	
		next if($actual{ptr} eq "n");

		if ($actual{ptr} eq "d") 
		{
			$leftresult.="(";
			$rightresult = ")" . $rightresult;
			push(@stack,$field->[$actual{jcoord}-1][$actual{icoord}+1]);
			print("Going diagonal to $actual{jcoord} $actual{icoord}\n");
		}
		elsif ($actual{ptr} eq "l") 
		{	
			$rightresult = "." . $rightresult;
			push(@stack,$field->[$actual{jcoord}-1][$actual{icoord}]);
			print("Going left to $actual{jcoord} $actual{icoord}\n");
		}
		elsif ($actual{ptr} eq "u") 
		{
			$leftresult.=".";
			push(@stack,$field->[$actual{jcoord}][$actual{icoord}+1]);
			print("Going down to $actual{jcoord} $actual{icoord}\n");
		}
		elsif ($actual{ptr} eq "b")
		{
			push(@stack,$field->[$actual{k}+1][$actual{icoord}]);
			push(@stack,$field->[$actual{jcoord}][$actual{k}]);
			print("Jumping to " ,$actual{k}+1," $actual{icoord} and $actual{jcoord} $actual{k}\n");
		}
	} 
	return $leftresult . $rightresult;
}


sub printField
{
	my $field = shift;
	my $size  = shift;
	my $sequence = shift;
	print("   ");
	for (my $j = 0 ; $j< $size ; $j++)
	{
		print(" " .substr($sequence,$j,1) . " ");
	}
	print("\n");

	for (my $i = 0 ; $i< $size ; $i++)
	{ 
		print(" " . substr($sequence,$i,1) . " ");
		for (my $j = 0 ; $j < $size ; $j++)
		{
			if (defined($field->[$j][$i]{$view}))
			{
				print(" ",$field->[$j][$i]{$view}, " ");
			}
			elsif($j<$i)
			{
				print("   ");
			}
			else
			{
				print(" . ");
			}
		}
		print("\n");
	}
}

sub initializeField
{
	my $field = shift;
	my $size  = shift;
	for (my $j = 0 ; $j < $size ; $j++)
	{
		for (my $i = 0 ; $i < $size ; $i++)
		{
			if (($i == $j) || ($i == $j + 1))
			{
				$field->[$j][$i]{score} = 0;
				$field->[$j][$i]{ptr}= "n";
			}
		}
	}
}

sub main
{
	my $sequence;
	my @field;
	if (scalar(@ARGV) == 0)
	{
		print("Error, filename needed\n");
	}
	else
	{
		print($sequence= &readFile($ARGV[0]), "\n");
		if(scalar(@ARGV) > 1)
		{
			if((lc($ARGV[1]) eq "score") || (lc($ARGV[1]) eq "ptr") || (lc($ARGV[1]) eq "icoord") || (lc($ARGV[1]) eq "jcoord"))
			{
				$view = $ARGV[1];
			}
		}
		my $size = length($sequence);
		&initializeField(\@field, $size);
		&fill_array(\@field, $size,$sequence);
		&printField(\@field, $size,$sequence);
		print("\n", $sequence, "\n" , &traceback(\@field,$sequence). "\n");
	}

}

&main;

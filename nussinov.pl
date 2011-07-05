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
	if ((($i eq 'A') && ($j eq 'U')) || (($j eq 'U') && ($i eq 'A')))
	{
		return 1;
	}
	if ((($i eq 'G') && ($j eq 'C')) || (($j eq 'C') && ($i eq 'G')))
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
			$field->[$x][$x-$j]{score} = $resultHash->{score};
			$field->[$x][$x-$j]{ptr} = $resultHash->{ptr};
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

	
	my %bifork = ( score => 0, ptr => 0);
	my $ktemp = 0;
	for (my $k=$j; $k<$i; $k++)
	{
		$ktemp=$field->[$j][$k]{score} + $field->[$k+1][$i]{score};
		if($ktemp > $bifork{score})
		{
			$bifork{score}=$ktemp;
			$bifork{ptr}=$k;
		}
	}

	push(@results,\%diag);
	push(@results,\%up);
	push(@results,\%left);
	push(@results,\%bifork);

	$max = (sort { $a->{score} <=> $b->{score}  }  (@results))[-1];    

	return $max;
}

sub traceback
{
	my $field = shift;
	my $sequence = shift;
	my $j = length($sequence)-1;
	my $i = 0;
	my $leftresult="";
	my $rightresult="";
	while ($field->[$j][$i]{ptr} ne "n")
	{
		if ($field->[$j][$i]{ptr} eq "d") 
		{
			$leftresult.="(";
			$rightresult = ")" . $rightresult;
			$i++;
			$j--;
			print("Going diagonal to $j $i\n");
		}
		elsif ($field->[$j][$i]{ptr} eq "l") 
		{	
			$rightresult = "." . $rightresult;
			$j--;
			print("Going left to $j $i\n");
		}
		elsif ($field->[$j][$i]{ptr} eq "u") 
		{
			$i++;
			$leftresult.=".";
			print("Going down to $j $i\n");
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
			if((lc($ARGV[1]) eq "score") || (lc($ARGV[1]) eq "ptr"))
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

#############################################################################################
# Created Monday, February 02, 2009: Version(BCV1.16.1)
#############################################################################################
# This vBCV1.16 is designed to Vizualize F5 Networks BigIP.conf files. 
# This program has several Dependancies. BigIP::Parser in this file is not
# maintained anyware but whith in this program distrobution.
# For more information please contact the author at thompson.mike@gmail.com.
#
# Please read the README.txt file for more information.
#############################################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#############################################################################################*

use Getopt::Long;
use Math::Round;
use BigIP::ParseConfig;
use GraphViz;
use Net::Netmask;
use Cwd qw(realpath);
use Cwd;  

#Declare CLI $vars
my $vs1 = "";
my $config ="";
my $new_dir="";
my $e = "";
###get opt
GetOptions ('v:s' => \$vs1,
	    'f:s' => \$config,
	    'd:s' => \$new_dir,
	    'e:s' => \$e,
	    help   => sub{ print " Thank you for using BigIP Configuration Visualizer (BCV 1.16.1) \n -v = <VS_NAME> this prints the specified virtual server.\n     Default is to print all\n\n -f =<Config_File_Name> specify the configuration file\n\n -d specifies a directory you want the images in. \n      Has to be in Current working Directory:\n      ".getcwd."\n      Default is /img) \n\n -e Define image format options: svg, png (default is jpg) \n\n -h for help but you already found it\n"; exit; });


if ( $new_dir ne "") {
        $path = getcwd;
    $dir = $path."/".$new_dir;
   
 }else{
   $path = getcwd;
    $dir = $path."/img";
    
    }

$perm = 755;


sub makeDir {
  if (-e "$dir"){ problem("Directory ($dir ) already exists.\n") } # Checks for existing
  mkdir ($dir,$perm) || problem("Directory already exist ($dir)\n");

  }# end sub makedir

sub problem{
  print "$_[0]\n";
}# end sub problem



#build regex for parsing configuration
$re1='((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))(?![\\d])';	# IPv4 IP Address 1
$re2='.*?';	# Non-greedy match on filler
$re3='((?:[a-z0-9_]*$))';	# Grab the port 
$re=$re1.$re2.$re3;
$rert=$re1.$re2.$re1;


######Build bigip parser referance

if ( $config ne "" ) {
    
  $bip = new BigIP::ParseConfig( $config );

} else {

  $bip = new BigIP::ParseConfig( 'bigip.conf');

}


if ( $e eq "svg") {
	  $ext = "svg"; 

} elsif ( $e eq "png" ) {

	$ext ="png"; 
} else {
	$ext = "jpg"; 
}

#set counters
my $counter = 0;
my $d = 1;
my $k = 0;
my $j = 0;
####Set some arrays up
#GW and Routes
my @rtarry ="";
#Vlans and Floaters
my @vlsi = "";
#Floaters and Netmask
my @sinm = "";
#GatePool Members
my @dgm = "" ;
#dont draw if you are in this array
my @dnd = "" ;




foreach my $vs ( $bip->virtuals() ){

	    if ( $vs =~ /address/ ) {
             next;
            } else {
            $counter++;
           }
}



##########check to see if VS is real from CLI opt. If it is not exit0. 
##########if no option is given parse through all Virtuals
if ($vs1 ne "") {
 
       foreach my $vs ( $bip->virtuals() ){
	 push(@vsa, $vs);    
	    }
       $found = grep /$vs1/, @vsa;
	$images = $dir."/".$vs1.".".$ext;
	if ( $found == 1){
	makeDir();
	build($vs1, $bip, $images);
    	 system(($^O eq 'MSWin32') ? 'cls' : 'clear');
	    print "BCV has completed diagraming Virtual Server: ".$vs1." \n";
	}else{
	    
	print "\n Virtual Server does not Exist! \n \n";
	exit 0;
	   
	}

	
	
} else {
	makeDir();
    foreach my $vs ( $bip->virtuals() ){
    
	    if ( $vs =~ /address/ ) {
	    next;
	    } else {
	    $images = $dir."/".$vs.".".$ext;
	    system(($^O eq 'MSWin32') ? 'cls' : 'clear');
	    print "Drawing Virtual Server ".$vs." which is " .$d." of ".$counter."\n";
	    
	    build($vs, $bip, $images);
	    if ($d == $counter){
	    system(($^O eq 'MSWin32') ? 'cls' : 'clear');
	    print "BCV has completed diagraming ".$d." Virtual Servers\n";
	    }
	    $d++;
	    }


    }
}





#####Build Route objects and place into an associative array

sub bro { 

    my $g=shift;
	
	foreach my $route ( $bip->routes() ) {
           
	    if ( $route ne "" ) {    

		$gw = $bip->route($route)->{'gateway'};
    
		    if ( $gw ne "" ) { 
		
			
			    if ( $gw =~ /default/){	
	    	
				 $rt3= '0.0.0.0/0';
			    
			    } else {
	     
				 if ($route =~ m/$rert/is){
		    
					$rtprefx=$1;
		    			$rtmask=$2;
		
				 } else {
		    
					$rtprefx='0.0.0.0';
					$rtmask='0.0.0.0'; 
				 }  				
					
				$prefix = Net::Netmask->new("$rtprefx", "$rtmask")->bits;
				$rt3 = $rtprefx.'/'.$prefix;
	                    }

		  
		    } else {
    

			$gw = $bip->route($route)->{'pool'};
						
			   if ( $gw =~ /default/){	
	    	
				 $rt3= '0.0.0.0/0';
			    
			    } else {
	     
				 if ($route =~ m/$rert/is){
		    
					$rtprefx=$1;
		    			$rtmask=$2;
		
				 } else {
		    
					$rtprefx='0.0.0.0';
					$rtmask='0.0.0.0'; 
				 }  		
        			 $prefix = Net::Netmask->new("$rtprefx", "$rtmask")->bits;
				$rt3 = $rtprefx.'/'.$prefix;
			    }
				    
			foreach my $member ( $bip->members( $gw ) ) {
				    if ($member =~ m/$re/is){
					$member=$1;
					$port2=$2;
        			    }
	        		if ($member ne ""){
				   if ($member ne "0"){
				 $g->add_node("Gateway_Pool: ".$member, shape => 'house', color => 'darkslategray1', style => 'filled'); 
				unshift(@dgm, $member, $gw);	   
			    	    }
				  }  
		         }
		    
        
			   }
		

	}else{
	    
	   next;
	}


if ( $gw =~ m/$re2/is) {
foreach my $member ( $bip->members( $gw ) ) {
	 if ($member =~ m/$re/is){
	    $member=$1;
	    $port2=$2;
         }
     if ($member ne ""){
	if ($member ne "0"){
    $g->add_node("Gateway: ".$gw); 
    $g->add_edge( "Gateway: ".$gw => "Gateway_Pool: ".$member);
	}
	}
    }
}
#print $rt3."  via  ".$gw."   1\n";
unshift(@rtarry, $rt3, $gw);
unshift(@dgm, $member, $gw);
   }
    %rtmx = @rtarry;
    %dgmx = @dgm;


return(%rtmx, %dgmx);
}


#######Build SelfIP and VLANs


sub bsv {
my $g=shift;
    foreach my $selfs ( $bip->selfss() ){
	
	if ( $selfs ne "" ) {
	
	$vlan = $bip->selfs($selfs)->{'vlan'};
	$sip = $selfs;
	$netm = $bip->selfs($selfs)->{'netmask'};
	$sip2 = new Net::Netmask ($sip, $netm);

	unshift(@vlsi, "$sip2", "$vlan");
	unshift(@sinm, "$sip2", "$netm");	
    
	}
}
    %vlmx = @vlsi;
    %simx = @sinm;



return(%vlmx, %simx);


}

sub gwv {
my $g=shift;
    while (($rt3, $gw) = each(%rtmx)){

	if ($rt3 ne "" ){
	    
	    if ( $gw =~ m/$re1/is) {

		next;



	   } else { 
		while (($sip, $netm) = each(%simx)){

	        if ($sip ne "" ){
			    
		    if ( $gw != /default/ ) {
			$block = new Net::Netmask ("$rt3");
			$block2 = new2 Net::Netmask ("$ipaddress2");  

			    if ($block->contains("$block2")) {
				$g->add_edge( "Gateway: ".$gw => "VLAN: ".$vlan);
			    }
		    }
	      }
	  }
      }
   }

 }
}
#connect puul members to routes 
sub cmr {	
	my $g= $_[0];
	my $member= $_[1];	    
	      
		while (($rt3, $gw) = each(%rtmx)){
			
			 if ($rt3 != '0.0.0.0/0') {
			    if ($rt3 ne "" ){
				  
				  $block = new Net::Netmask ("$rt3");
				  $block2 = new2 Net::Netmask ("$ipaddress2");  
                                         
					  if ($block->contains("$block2")) {
						return($rt3, $gw);
		  				  
						}
					   }
				}
			}			  
	
		} 


###connect pool members to vlans and pools		
sub cmv {
		$vlan = "";
                $sip = "" ;
		my $ipaddress2 = $_[0];
		   #my  %simx = $_[1];
		    #print $ipaddress2."\n";
			while (($sip, $netm) = each(%simx)){
                         
				if ($sip ne "" ){
				   
				      $block = new Net::Netmask ("$sip");
				      $block2 = new2 Net::Netmask ("$ipaddress2");  
                                       #print "BLOCK: ".$block."\n";
				       #print "BLOCK2: ".$block2."\n";	
					if ($block->contains("$block2")) {
					#    print "TRUE\n";
						$vlan = $vlmx{$sip};
						
						   return($vlan, $sip); 
					} 
			
				}		
			 } 

		}		
       
	

sub build {

	my $g = GraphViz->new();
	my $g = GraphViz->new(rankdir  => 1);
	my $vs=$_[0];
	my $bip=$_[1];
	my $images=$_[2];
     		
        
	    &bro($g);
	    &bsv($g);	
	    &gwv($g);


        $des = $bip->virtual($vs)->{'destination'};
	$snat = $bip->virtual($vs)->{'snat'};
	$per = $bip->virtual($vs)->{'persist'};
	$fp = $bip->virtual($vs)->{'fallback'};
	$httpclass = $bip->virtual($vs)->{'httpclass'};
	$pro = $bip->virtual($vs)->{'profile'};
	$irule = $bip->virtual($vs)->{'rule'};	
		if ($irule eq "") {
			$irule = $bip->virtual($vs)->{'rules'};		
		    }
   
	$translate = $bip->virtual($vs)->{'translate'};
	$ipp = $bip->virtual($vs)->{'ip'};
        $pool = $bip->virtual($vs)->{'pool'};
	if ($pool ne "" ){
        $monitor = $bip->pool($pool)->{'monitor'};
	$lb = $bip->pool($pool)->{'lb'};
	}
      
      
     #make sure we do not get null data back from each object
        if ( $vs ne "" ) {
        
	    $g->add_node("virtual: ".$vs, shape => 'egg', color => 'orangered1', style => 'filled');
 
        }

#check if des is null
         if ($des ne "" ) {
#if it equals any any then 
            if ($des eq "any:any") {
                $ipaddress1='0.0.0.0/0';
		$port='any';
             # draw objects
		$g->add_node($ipaddress1, shape => 'diamond', color => 'chartreuse', dir => 'both');
		$g->add_node($port, shape => 'diamond',color => 'cyan', style => 'dotted');
        	$g->add_edge($ipaddress1 => $port);
		$g->add_edge($port => "virtual: ".$vs);
		 
		
		    while (($rt3, $gw) = each(%rtmx)) {

			    if ($rt3 ne "" ){
			    $g->add_edge("Route: ".$rt3 => $des);
			
			    }
		    }
		    
		         
	 } else {

		    if ($des =~ m/$re/is){
			$ipaddress1=$1;
			$port=$2;
	            }
            $g->add_node($ipaddress1, shape => 'diamond', color => 'chartreuse');
	    $g->add_node($port, shape => 'diamond',color => 'cyan', style => 'dotted');
            $g->add_edge($ipaddress1 => $port);
	    $g->add_edge($port => "virtual: ".$vs);
	        
	  
			while (($sip, $netm) = each(%simx)){

				if ($sip ne "" ){
				    
				      $block = new Net::Netmask ($sip);
				      $block2 = new2 Net::Netmask ("$ipaddress1");  

					if ($block->contains("$block2")) {
					    
						$vlan = $vlmx{$sip};
		                                 $g->add_node("VLAN: ".$vlan);
						 $g->add_node("Network:".$block);
	                                         $g->add_edge("VLAN: ".$vlan => "Network:".$block);
						$g->add_edge( $ipaddress1 => "VLAN: ".$vlan , dir => 'both');
				 
					}

				}
			}
	       } 
	} 
	if ($snat ne "" ) {
	    
	    $g->add_node($snat, shape => 'diamond', color => 'magenta');
	
        }
	 if ($ipp ne "" ) {
         $g->add_node("ip  ".$ipp, shape => 'diamond', color => 'chartreuse2');
	 $g->add_edge( "ip  ".$ipp=>  $port, dir => 'both', color => 'chartreuse2');
        }
	 if ($per ne "" ) {
         $g->add_node("Persistance: ".$per, shape => 'record', color => 'lightblue');
	 $g->add_edge( "Persistance: ".$per=>  "virtual: ".$vs, dir => 'both', color => 'lightblue');
        }
	 if ($fp ne "" ) {
       $g->add_node("Fallback: ".$fp, shape => 'record', color => 'steelblue2');
	$g->add_edge( "Fallback: ".$fp => "virtual: ".$vs, dir => 'both', color => 'steelblue2');
        }
	if ($httpclass ne "" ) {
       $g->add_node("httpclass: ".$httpclass, shape => 'circle', color => 'darkolivegreen3');
	$g->add_edge( "httpclass: ".$httpclass => "virtual: ".$vs, dir => 'both', color => 'darkolivegreen3');
        }
	if ($pro ne "" ) {
        $g->add_node("Profile: ".$pro, color => 'chocolate2');
	$g->add_edge( "virtual: ".$vs=>  "Profile: ".$pro, color =>'chocolate2');
        }
	if ($irule ne "" ) {
	$g->add_node("iRule: ".$irule, shape => 'tripleoctagon', color => 'goldenrod1');
	$g->add_edge( "virtual: ".$vs=>  "iRule: ".$irule, color => 'goldenrod1');
        }
	 if ($translate ne "" ) {
         $g->add_node("trasnslate: ".$translate, shape => 'triangle', color => 'lavenderblush3');
	 $g->add_edge( "virtual: ".$vs=>  "trasnslate: ".$translate, color => 'lavenderblush3');
        }
	
	 if ($pool ne "" ) {
         $g->add_node($pool, shape => 'box3d', color => 'sienna4');
	 
	     if ( $snat ne "" ) {
		$g->add_edge( $snat =>  "virtual: ".$vs,  dir => 'both', color => 'magenta');
        	$g->add_edge( "virtual: ".$vs=>  $pool, color => 'magenta');
            } else {

		$g->add_edge( "virtual: ".$vs=>  $pool);
	    }

	    if ( $lb ne "" ) {
	 
	        $g->add_node($lb, color => 'lightblue');
	        $g->add_edge( $lb=>  $pool);   
	    } 
	#loop through the members

	    $member = $bip->members($pool);

	    if ($member ne ""){
          foreach my $member ( $bip->members( $pool ) ) {
		
	        $g->add_node($member, shape => 'house', color => 'burlywood');
		    #$g->add_edge( $pool=>  $member);
		     if ($member =~ m/$re/is){
			$ipaddress2=$1;
			$port2=$2;
        	    }
		&cmr($ipaddress2, %rtmx);
		&cmv($ipaddress2, %simx);
                       
			if ( $snat ne "" ) {  
			  if ($vlan ne "") { 
			    
			    $g->add_node("VLAN: ".$vlan);
			        if ($sip ne "") {
			    # $g->add_node("Network:".$sip);
	                       
				#$g->add_edge("VLAN: ".$vlan=> "Network:".$sip, color => 'magenta');    				
		        	#push(@dnd, $vlan , $sip);
				}			
			    $g->add_edge( $member => "VLAN: ".$vlan, color => 'magenta');
			    $g->add_edge( $pool=>  $member, color => 'magenta');
			    } else {
				$g->add_node("VLAN: ".$vlan);
			        $g->add_edge( $pool=>  $member, color => 'magenta');
				
			    }
			    if ( $rt3 ne ""){
			     if ($gw ne "" ) {
				if ($k == 0) {
				$g->add_node("Gateway: ".$gw);
		           	$g->add_node("Route: ".$rt3);
			        $k++;
				}
			    $g->add_edge( $member => "Route: ".$rt3, color => 'magenta');
			    $g->add_edge( "Route: ".$rt3 => "Gateway: ".$gw, color => 'magenta');
			    }
			    }
			}else {
		if ($vlan ne "") { 
			    $g->add_node("VLAN: ".$vlan);
			 if ($sip ne "") {
			  #  $g->add_node("Network:".$sip);
	                  #  $g->add_edge("VLAN: ".$vlan=> "Network:".$sip);    				
		            }			
			    $g->add_edge( $member => "VLAN: ".$vlan);
			    $g->add_edge( $pool=>  $member);
			} else {
                          
			        $g->add_edge( $pool=>  $member);
			}
			    if ( $rt3 ne ""){
			     if ($gw ne "" ) {
				if ($k == 0) {
				$g->add_node("Gateway: ".$gw);
		           	$g->add_node("Route: ".$rt3);
			        $k++;
				}
			    $g->add_edge( $member => "Route: ".$rt3);
			    $g->add_edge( "Route: ".$rt3 => "Gateway: ".$gw);
			}
		}
	}
		
}
        # gab the monitor for the pool
			     if ( $monitor ne "" ) {
	 
			     $g->add_node("Monitors: ".$monitor, color => 'peru'  );
			     $g->add_edge( "Monitors: ".$monitor => $pool, color => 'peru' );
         
			    }
	
        

	}
}


if ( $e eq 'svg') {
print $g->as_svg($images); 

 } elsif ( $e eq 'png' ) {

print $g->as_png($images); 
}else {
print $g->as_jpeg($images); 
}
 
$g = "";

	}





	


 


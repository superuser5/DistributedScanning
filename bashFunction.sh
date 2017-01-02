#add this functions to your bashrc file or source them when you want to operate your scanners and files 
#you need to change the vultr API key here 
#setup
function DistributedScan-Setup(){
wget https://raw.githubusercontent.com/royharoush/rtools/master/json2csv.py -O /usr/bin/json2csv.py && chmod +x /usr/bin/json2csv.py
apt-get install jq -y > /dev/nul 
printf "Finished ! "
}
#enable SSH-Agent to start when terminal starts, leaving this function will disable automated data retreival. 
eval $(ssh-agent)

#Vultr 
function DistributedScan-vultrGetAllserversCSV(){
rm vulter-servers.csv
curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json >> vulter-servers.csv && libreoffice vulter-servers.csv &
}
function DistributedScan-vultrGetAllserversPrint(){
rm vulter-servers.csv
curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json >> vulter-servers.csv &&  cat vulter-servers.csv
}

function DistributedScan-vultrGetAllserversLight(){
rm vulter-servers.csv
curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json |  cut -d"," -f1,10,16
}

function DistributedScan-vultrGetScannersIP(){


curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json |grep scan | cut -d "," -f10 > scanners_IP
}

function DistributedScan-vultrGetScannersSubID(){

curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json |grep scan | cut -d "," -f1 > scanners_subid

}

#vultr
#Data  Retreival
function DistributedScan-vpsGetResults (){
ssh-add
echo "what is the project name:"
read project
mkdir -p /root/projects/$project
cd /root/projects/$project
rm vulter-servers.csv
curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/list > servers.json && <servers.json jq '.'  | sed s'/},/},\n/' > servers-json.json && json2csv.py servers-json.json > servers.csv && cat servers.csv |  cat servers.csv | grep scanmachine1| cut -d"," -f10 > scanners_IP 
pssh -i -h /root/projects/$project/scanners_IP  -x "-oStrictHostKeyChecking=no" ls 
#install rsync on remote servers
pssh -i -h /root/projects/$project/scanners_IP  -x "-oStrictHostKeyChecking=no" apt-get install rsync > /dev/null
pssh -i -h /root/projects/$project/scanners_IP  -x "-oStrictHostKeyChecking=no" apt-get install rsync > /dev/null
for i in $(cat /root/projects/$project/scanners_IP); do rsync -avz --remove-source-files -e ssh  root@$i:/nmap_output/* /root/projects/$project --rsync-path=/usr/bin/rsync & done 
}
#data retreival 


#Delete scanners
function DistributedScan-vultrDeleteScanners(){
echo "Make sure you don't have any more scans running on your scanners."
echo "Run the Data Fetching function one last time and wait for it to finish."
echo -e " \e[91m \e[1;4m after you've made sure you retreived all the results and no new scans are running, run the following command:"
echo -e "\e[0mfor i in \$(cat scanners_subid);do curl -H 'API-Key: 3XDA4RSLLQJ6MNJO3SVLNKBXIREJVROKFHTA' https://api.vultr.com/v1/server/destroy --data 'SUBID='\$i'';done"
}

function DistributedScan-parseResults(){
wget https://raw.githubusercontent.com/royharoush/rtools/master/nmaParseClean.sh -O parse.sh && bash parse.sh
}


##Create Evasion Command file 
function DistributedScan-commandFileCreateEvasive(){
if [[ -f ./targets && -f ./ports ]];then
	echo "Targets and Ports exists"
	echo "Creating command file" 
	echo "This may take a while, please do not CTRL+C"
	printf "53\n80\n443\n67\n20" > /root/randomport
	for ip in $(nmap -iL targets -sL -Pn -sn -n  | grep "Nmap scan report"| sort -u  |shuf | sort -R | cut -d" " -f 5  ) ; do for port in $(cat ports); do printf "nmap $ip -p $port --source-port $( cat  ~/randomport  | shuf  | head -1)  --data-length $( shuf -i 50-100 -n 1)  --mtu $( shuf -i 50-100 -n 1)\n" ; done ;done > commandsFile

else
	echo "targets or ports missing"
fi
}

##Distributed Scan Process ##


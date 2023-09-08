#pragma rtGlobals=3		// Use modern global access method and strict wave access.
menu "Macros"
	"Load & chop output curves", chop_output()
	"Load & chop transfer curves", chop_transfer()
	"Load & chop transfer curves seperate fwd&rev scans", chop_transfer_hysteresis()
end

function chop_output()

	open/R/D/T="????" fileID //get fileID
	
	String FileName
	FileName=ParseFilePath(3, S_filename, ":", 0, 0) //grabs the name of the file
	LoadWave/J/D/N=WaveID/W/K=0/L={12,12,0,0,0} S_FileName //load waves
	
	print filename
	
	Wave Vdrain, Idrain, Vgate, gds, Rds
	
	variable n, gate, finished = 0, length, chop_length, maxgate, mingate, chop_num = 0
	string device, nameId, nameVd, nameG, nameR
	
	prompt device, "Device Name:"

	doprompt "Enter Device Name", device //creates popup window
		if (V_Flag)
			return -1
		endif

	length = DimSize(Vgate,0)
	//maxgate = Vgate[(length)]
	mingate = Vgate[0]
	
	gate = mingate //initialise gate value	
	for (n=0; finished < 1; n+=1)
		if (ABS(Vgate[n]) > ABS(gate))
			chop_length = n
			finished = 1
		elseif (n == length)
			chop_length = length
			finished = 1
		endif
		gate = Vgate[n]	
	endfor

	make/n=(chop_length) tempVd //temporary V_drain wave
	for (n=0; n < chop_length; n+=1)
		tempVd[n] = Vdrain[n]
	endfor
	nameVd = device+"_output_Vd" //set name for Vd wave
	Rename tempVd $nameVd //rename Vd wave
	
	make/n=(chop_length) tempId //temporary I_drain wave
	make/n=(chop_length) tempG //temporary Gds wave
	make/n=(chop_length) tempR //temporary Rds wave
			
	gate = mingate //initialise gate value	
	for (n=0; n < length; n+=1)
		if (ABS(Vgate[n]) > ABS(gate))
			nameId = device+"_output_Id_"+num2str(gate)+"Vg"
			nameG = device+"_output_gds_"+num2str(gate)+"Vg"
			nameR = device+"_output_Rds_"+num2str(gate)+"Vg"
			//SetScale d 0,0,"A", $nameId
			Rename tempId $nameId
			Rename tempG $nameG
			Rename tempR $nameR
			make/n=(chop_length) tempId //temporary I_drain wave
			make/n=(chop_length) tempG //temporary Gds wave
			make/n=(chop_length) tempR //temporary Rds wave
			chop_num+=1
		endif
		tempId[(n-chop_length*chop_num)] = (Idrain[n])
		tempG[(n-chop_length*chop_num)] = (gds[n])
		tempR[(n-chop_length*chop_num)] = (Rds[n])
		gate = Vgate[n]
	endfor
	nameId = device+"_output_Id_"+num2str(gate)+"Vg"
	nameG = device+"_output_gds_"+num2str(gate)+"Vg"
	nameR = device+"_output_Rds_"+num2str(gate)+"Vg"
	//SetScale d 0,0,"A", $nameId
	Rename tempId $nameId
	Rename tempG $nameG
	Rename tempR $nameR	
	
	killwaves Vdrain, Idrain, Vgate, gds, Rds
end

function chop_transfer()

	open/R/D/T="????" fileID //get fileID
	
	String FileName
	FileName=ParseFilePath(3, S_filename, ":", 0, 0) //grabs the name of the file
	LoadWave/J/D/N=WaveID/W/K=0/L={12,12,0,0,0} S_FileName //load waves
	
	print filename
	
	Wave Vgate, Idrain, Igate, gm, Vdrain, IdrainPerWg, gmPerWg
	variable n, drain, finished = 0, length, chop_length, maxdrain, mindrain, chop_num = 0
	string device, nameId, nameVg, nameIg, namegm, namesqrtId
	
	prompt device, "Device Name:"

	doprompt "Enter Device Name", device //creates popup window
		if (V_Flag)
			return -1
		endif

	length = DimSize(Vdrain,0)
	//maxdrain = Vdrain[(length)]
	mindrain = Vdrain[0]
	
	drain = mindrain //initialise drain value	
	
	//now loop over drain voltage wave to measure number of points per drain voltage
	for (n=0; finished < 1; n+=1)
		if (ABS(Vdrain[n]) > ABS(drain))
			chop_length = n
			//print chop_length
			finished = 1
		elseif (n == length)
			chop_length = length
			finished = 1
		endif
		drain = Vdrain[n]	
	endfor

	make/n=(chop_length) tempVg //temporary V_gate wave
	for (n=0; n < chop_length; n+=1)
		tempVg[n] = Vgate[n]
	endfor
	nameVg = device+"_transfer_Vg" //set name for Vd wave
	Rename tempVg $nameVg //rename Vd wave
	
	make/n=(chop_length) tempId //temporary I_drain wave
	make/n=(chop_length) tempsqrtId //temporary sqrt(Id) wave
	make/n=(chop_length) tempIg //temporary Gds wave
	make/n=(chop_length) tempgm //temporary Rds wave
			
	drain = mindrain //initialise gate value	
	for (n=0; n < length; n+=1)
		if (ABS(Vdrain[n]) > ABS(drain)) //if next drain voltage reached, rename all the temp waves and make new ones
			nameId = device+"_transfer_Id_"+num2str(drain)+"Vd"
			nameIg = device+"_transfer_Ig_"+num2str(drain)+"Vd"
			namegm = device+"_transfer_gm_"+num2str(drain)+"Vd"
			namesqrtId = device + "_transfer_sqrtId_"+num2str(drain)+"Vd"
			//SetScale d 0,0,"A", $nameId
			Rename tempId $nameId
			Rename tempIg $nameIg
			Rename tempgm $namegm
			Rename tempsqrtId $namesqrtId
			make/n=(chop_length) tempId // new temporary I_drain wave
			make/n=(chop_length) tempsqrtId //new temporary sqrt(Id) wave
			make/n=(chop_length) tempIg //new temporary Gds wave
			make/n=(chop_length) tempgm //new temporary Rds wave
			chop_num+=1 //number of chops done
		endif
		tempId[(n-chop_length*chop_num)] = (Idrain[n]) //set value in temp wave with appropriate index
		tempsqrtId[(n-chop_length*chop_num)] = SQRT(ABS(Idrain[n]))
		tempIg[(n-chop_length*chop_num)] = (Igate[n])
		tempgm[(n-chop_length*chop_num)] = (gm[n])
		drain = Vdrain[n]
	endfor
	//rename last set of waves
	nameId = device+"_transfer_Id_"+num2str(drain)+"Vd"
	nameIg = device+"_transfer_Ig_"+num2str(drain)+"Vd"
	namegm = device+"_transfer_gm_"+num2str(drain)+"Vd"
	namesqrtId = device + "_transfer_sqrtId_"+num2str(drain)+"Vd"
	Rename tempId $nameId
	Rename tempIg $nameIg
	Rename tempgm $namegm
	Rename tempsqrtId $namesqrtId	
	
	//tidy up
	killwaves Vgate, Idrain, Igate, gm, Vdrain, IdrainPerWg, gmPerWg
end

function chop_transfer_hysteresis()

	open/R/D/T="????" fileID //get fileID
	
	String FileName
	FileName=ParseFilePath(3, S_filename, ":", 0, 0) //grabs the name of the file
	LoadWave/J/D/N=WaveID/W/K=0/L={12,12,0,0,0} S_FileName //load waves
	
	print filename
	
	Wave Vgate, Idrain, Igate, gm, Vdrain, IdrainPerWg, gmPerWg
	variable n, drain, finished = 0, length, chop_length, maxdrain, mindrain, chop_num = 0
	string device, nameId, nameVg, nameVg_rev, nameIg, namegm, namesqrtId, nameabsId
	
	prompt device, "Device Name:"

	doprompt "Enter Device Name", device //creates popup window
		if (V_Flag)
			return -1
		endif

	length = DimSize(Vdrain,0)
	//maxdrain = Vdrain[(length)]
	mindrain = Vdrain[0]
	
	drain = mindrain //initialise drain value	
	
	//loop over gate voltage wave to find spot where it changes direction for return sweep
	for (n=1; finished < 1; n+=1)
		if (Vgate[n] - Vgate[n-1] == 0)
			chop_length = n //this is the NUMBER OF POINTS in the wave, because Igor starts at 0 the final point will be n-1
			//print chop_length
			finished = 1
		elseif (n == length)
			chop_length = length
			finished = 1
		endif	
	endfor

	//make temporary V_gate waves
	make/n=(chop_length) tempVg_fwd
	make/n=(chop_length) tempVg_rev
	for (n=0; n < chop_length; n+=1)
		tempVg_fwd[n] = Vgate[n]
		tempVg_rev[n] = Vgate[chop_length-1-n]
	endfor
	nameVg = device+"_transfer_Vg_fwd" //set name for forward Vg wave
	nameVg_rev =  device+"_transfer_Vg_rev" //set name for reverse Vg wave
	//rename waves
	Rename tempVg_rev $nameVg_rev
	Rename tempVg_fwd $nameVg 
	
	make/n=(chop_length) tempId //temporary I_drain wave
	make/n=(chop_length) tempabsId //temporary Abs(Id) wave
	make/n=(chop_length) tempsqrtId //temporary sqrt(Id) wave
	make/n=(chop_length) tempIg //temporary Gds wave
	make/n=(chop_length) tempgm //temporary Rds wave
	
	//initialise drain value and set the first point of all waves (loop starts at second point)		
	drain = mindrain
	tempId[0] = (Idrain[0])
	tempabsId[0] = ABS(Idrain[0])
	tempsqrtId[0] = SQRT(ABS(Idrain[0]))
	tempIg[0] = (Igate[0])
	tempgm[0] = (gm[0])
	drain = Vdrain[0]
	
	variable forwardsweep = 1 //definition: 1 for fwd direction, -1 for reverse sweep	
	
	//loop over the length of the voltage scan and chop the raw data into separate waves
	for (n=1; n < length; n+=1)
		
		//if gate switches direction, rename all the temp waves and make new ones
		if (Vgate[n] - Vgate[n-1] == 0) 
			
			//set the names for the waves according to sweep direction (forward or reverse)
			if (forwardsweep == 1) 
				nameId = device+"_trans_Id_"+num2str(drain)+"Vd_fwd"
				nameIg = device+"_trans_Ig_"+num2str(drain)+"Vd_fwd"
				namegm = device+"_trans_gm_"+num2str(drain)+"Vd_fwd"
				nameabsId = device + "_trans_absId_"+num2str(drain)+"Vd_fwd"
				namesqrtId = device + "_trans_sqrtId_"+num2str(drain)+"Vd_fwd"
			elseif (forwardsweep == -1)
				nameId = device+"_trans_Id_"+num2str(drain)+"Vd_rev"
				nameIg = device+"_trans_Ig_"+num2str(drain)+"Vd_rev"
				namegm = device+"_trans_gm_"+num2str(drain)+"Vd_rev"
				nameabsId = device + "_trans_absId_"+num2str(drain)+"Vd_rev"
				namesqrtId = device + "_trans_sqrtId_"+num2str(drain)+"Vd_rev"
			endif
			//set units
			//SetScale d 0,0,"A", $nameId
			//rename the temp waves and create new temp waves
			Rename tempId $nameId
			Rename tempIg $nameIg
			Rename tempgm $namegm
			Rename tempabsId $nameabsId
			Rename tempsqrtId $namesqrtId
			make/n=(chop_length) tempId
			make/n=(chop_length) tempabsId 
			make/n=(chop_length) tempsqrtId 
			make/n=(chop_length) tempIg 
			make/n=(chop_length) tempgm
			
			//note change of sweep direction	
			forwardsweep*=-1				 
			//update number of chops done			
			chop_num+=1 
		endif
		
		//if gate hasn't changed direction, set values in temp wave with appropriate index
		tempId[(n-chop_length*chop_num)] = (Idrain[n])
		tempabsId[(n-chop_length*chop_num)] = ABS(Idrain[n])
		tempsqrtId[(n-chop_length*chop_num)] = SQRT(ABS(Idrain[n]))
		tempIg[(n-chop_length*chop_num)] = (Igate[n])
		tempgm[(n-chop_length*chop_num)] = (gm[n])
		drain = Vdrain[n]
		
	endfor
	
	//finally, rename the last set of waves from the loop (same as code in loop)
	if (forwardsweep == 1) 
		nameId = device+"_trans_Id_"+num2str(drain)+"Vd_fwd"
		nameIg = device+"_trans_Ig_"+num2str(drain)+"Vd_fwd"
		namegm = device+"_trans_gm_"+num2str(drain)+"Vd_fwd"
		nameabsId = device + "_trans_absId_"+num2str(drain)+"Vd_fwd"
		namesqrtId = device + "_trans_sqrtId_"+num2str(drain)+"Vd_fwd"
	elseif (forwardsweep == -1)
		nameId = device+"_trans_Id_"+num2str(drain)+"Vd_rev"
		nameIg = device+"_trans_Ig_"+num2str(drain)+"Vd_rev"
		namegm = device+"_trans_gm_"+num2str(drain)+"Vd_rev"
		nameabsId = device + "_trans_absId_"+num2str(drain)+"Vd_rev"
		namesqrtId = device + "_trans_sqrtId_"+num2str(drain)+"Vd_rev"
	endif
	//SetScale d 0,0,"A",'$nameId
	Rename tempId $nameId
	Rename tempIg $nameIg
	Rename tempgm $namegm
	Rename tempabsId $nameabsId
	Rename tempsqrtId $namesqrtId	
	
	//tidy up
	killwaves Vgate, Idrain, Igate, gm, Vdrain, IdrainPerWg, gmPerWg
end
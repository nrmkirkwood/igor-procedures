#pragma rtGlobals=3		// Use modern global access method and strict wave access.

menu "Abs Reference"
	"Reference", reference()
end

function Reference()
//takes the waves on top graph and applies a chosen reference wave 
//to correct absorbance for reference (solvent)
//uses function CommonX to match the x-values of the sample and 
//reference if they do not match i.e. start/end are different or interval is different

	string Ref
	prompt Ref, "Select reference", popup, WaveList("*",";","")
	
	doprompt "Select Reference absorbance wave", Ref
		if (V_Flag)
			return -1
		endif

	wave RefW = $Ref
	
	//now access the waves from top graph and apply the reference correction

	Variable index = 0
	string RawWaveName, list, traceName
	list = TraceNameList("",";",1)								// List of traces in top graph
	
	do
		traceName = StringFromList(index, list)				// Next trace name
		if (strlen(traceName) == 0)
			break												// No more traces
		endif
		
		WAVE SampleW = TraceNameToWaveRef("", traceName)		// Get wave ref
		
		//RawWaveName = "old_" + traceName					
		//print traceName, RawWaveName							//debug only
		//duplicate SampleW $RawWaveName						//save original absorbance before correcting with ref
	
		if (	(numpnts(SampleW) != numpnts(RefW)) || (pnt2x(SampleW,1) - pnt2x(SampleW,0)) != (pnt2x(RefW,1) - pnt2x(RefW,0)) || (pnt2x(SampleW,0) !=  pnt2x(RefW,0)) )																			
			CommonX(RefW, SampleW) 		
		// if different number of points,	different interval, or different start points, then	 match x-values of waves to same start, end and scale
		endif
		
		SampleW = -log(10^(-SampleW)/10^(-RefW))	//compute corrected absorbance with the two waves
				
		index += 1										
	while (1)												// loop till break above

end


function CommonX(w1,w2)
//this function matches two differently scaled waves with at least some common x-values 
//so that they have the same domain (i.e. same x-values) whilst preseving the corresponding y-values of each wave.
//Points of each wave that do not have a common x-value will be deleted.
//i.e. for w1 with x-values of {0, 1, 2, 3, 4, 5, 6} and w2 with x values of {2, 4, 6, 8, 10} it should modify both waves 
//to have only the common x-values {2, 4, 6} with the assosciated y-values for each wave.
//n.b. waves can have ascending or descending x-values, but it will not work if one is ascending and the other descending!
	
	wave w1
	wave w2
	Variable w1_i, w1_f, w1_int, w1_numpnts, w2_i, w2_f, w2_int, w2_numpnts

	w1_numpnts = numpnts(w1)
	w1_i = pnt2x(w1,0)
	w1_f = pnt2x(w1, w1_numpnts-1)
	w1_int = pnt2x(w1,1) - pnt2x(w1,0)					//get the number of points,initial, final, and interval values of x-scaled w1
		
	w2_numpnts = numpnts(w2)
	w2_i = pnt2x(w2,0)
	w2_f = pnt2x(w2, w2_numpnts-1)
	w2_int = pnt2x(w2,1) - pnt2x(w2,0)		//get the number of points,initial, final, and interval values of x-scaled w2

	variable X_f, X_i, X_int		//final and initial x values and interval
	variable ascending
	
	if (w1_f > W1_i)	//if wave is ascending in X values. Assume here that both are same so arbitrarily pick w1
		ascending = 1
		X_int = max(w1_int, w2_int)		//interval is the highest value of the two
		X_f = min(w1_f, w2_f)			//final X value is minimum of w1, w2
		X_i = max(w1_i, w2_i)			//initial X value is maximum of w1, w2
	else										//otherwise, wave must descend in X values
		ascending = 0
		X_int = min(w1_int, w2_int)		//interval is the lowest (highest negative) value of w1, w2
		X_f = max(w1_f, w2_f)			//final X value is maximum of w1, w2
		X_i = min(w1_i, w2_i)			//initial X value is minumum  of w1, w2
	endif
	
	variable numpoints = 1 + (X_f - X_i)/(X_int)		//number of points 	
	//print X_i, X_f, X_int, numpoints					//debug only
	
	duplicate/o w1 w1o			//make copies to preserve old x values for now
	duplicate/o w2 w2o
					
	Redimension/N=(numpoints) w1
	Redimension/N=(numpoints) w2			//redim waves and rescale with matched scales
	SetScale/P x, X_i, X_int, w1
	SetScale/P x, X_i, X_int, w2
	
	variable xnew, pxnew, pxold_2, pxold_1
	
	if (ascending == 1)													//positive interval
		for (xnew = (X_i) ; xnew <= (X_f) ; xnew+= (X_int))		//count forwards as waves start from lowest x value
			pxnew = x2pnt(w2, xnew)						//the new point value for each value of X in the matched waves
			pxold_2 = x2pnt(w2o, xnew)					//the old x value for w2
			pxold_1 = x2pnt(w1o, xnew)					//the old x value for w1
			w2[pxnew] = w2o[pxold_2]								//insert values into new waves from appropriate points of old waves 
			w1[pxnew] = w1o[pxold_1]
		endfor
	elseif (ascending == 0)
			for (xnew = (X_i) ; xnew >= (X_f) ; xnew+= (X_int))		//count backwards as waves start from highest x value
			pxnew = x2pnt(w2, xnew)						//the new point value for each value of X in the matched waves
			pxold_2 = x2pnt(w2o, xnew)					//the old x value for w2
			pxold_1 = x2pnt(w1o, xnew)					//the old x value for w1
			w2[pxnew] = w2o[pxold_2]								//insert values into new waves from appropriate points of old waves 
			w1[pxnew] = w1o[pxold_1]
		endfor
	endif	
	
	killwaves w2o, w1o		//clean up

end
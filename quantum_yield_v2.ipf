#pragma rtGlobals=1		// Use modern global access method.

menu "Macros"
	"Quantum Yield", Quantum_Yield()
end

function Quantum_Yield()

	DoAlert/T="Information" 0, "All absorbance waves must have the same range"

	string abs_ref, abs_sample, pl_ref, pl_sample, abs_x
	variable n_ref, n_sample, excitation, qy_ref, Ns, i
	prompt Ns, "Enter number of samples:"
	prompt qy_ref, "QY of reference:"
	prompt abs_x, "Select absorbance x-wave", popup, WaveList("*",";","")
	prompt abs_ref, "Select reference absorbance Y-wave", popup, WaveList("*",";","")
	prompt pl_ref, "Select reference PL Y-wave", popup, WaveList("*",";","")
	prompt n_ref, "Refractive index of ref:"
	prompt excitation, "Excitation wavelength:"
	
	doprompt "Select Reference Waves", abs_x, abs_ref, pl_ref, n_ref, qy_ref, excitation //creates popup window
		if (V_Flag)
			return -1
		endif	
	
	doprompt "Enter numer of samples:", Ns 
		if (V_Flag)
			return -1
		endif	
		
	make/n=(Ns)/O/T sample_name	//wave for sample names
	make/n=(NS)/O quantumyield		//wave for QY data
	
	variable index, f_ref, I_ref
	wave w_abs_x = $abs_x
	wave w_abs_ref = $abs_ref
	wave w_pl_ref = $pl_ref
	
	index = abs((excitation - w_abs_x[0])*(1/(w_abs_x[1]-w_abs_x[0]))) // calculate the index of the absorption wavelength for absorption waves from the absorption x-wave. Takes into account difference between points in x-wave.
	f_ref = 1-10^(-w_abs_ref[index])
	I_ref = area(w_pl_ref)
	
	for (i=0 ; i < Ns ; i+=1) //loop to calculate each sample's QY and add to wave
		
		prompt abs_sample, "Select sample absorbance Y-wave", popup, WaveList("*",";","")
		prompt pl_sample, "Select sample PL Y-wave", popup, WaveList("*",";","")
		prompt n_sample, "Refractive index of sample:"
	
		doprompt "Select Sample Waves", abs_sample, pl_sample, n_sample
			if (V_Flag)
				return -1
			endif
		
		wave w_abs_sample = $abs_sample
		wave w_pl_sample = $pl_sample
		variable f_sample, I_sample, QY

		f_sample = 1-10^(-w_abs_sample[index])
		
		I_sample = area(w_pl_sample)
		
		QY = qy_ref * (I_sample/I_ref) * (f_ref/f_sample) * (n_sample/n_ref)^2 //calculate QY
		
		sample_name[i]=pl_sample
		quantumyield[i]=QY
		
		print QY
		
	endfor
		
edit sample_name quantumyield
	
end
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
menu "Macros"
	"Load JVL data - new graph", load_JVL()
	"Load JVL data - append to top graph", load_JVL_append()
	"Load EL spectra", ELload()
	"Calculate EQE directly from EL", EQEcalc_direct()
	"Calculate EQE via luminance conversion", EQEcalc_lum()
	"Compare max efficiency", compare_efficiency_max()
	"Compare efficiency at certain current density", compare_efficiency_select()
	"Compare efficiency at certain luminance", compare_efficiency_selectlum()
end

function load_JVL()

	open/R/D/T="????" fileID //get fileID
	
	String FileName
	FileName=ParseFilePath(3, S_filename, ":", 0, 0) //grabs the name of the file
	LoadWave/J/D/W/K=0/L={5,6,0,0,3} S_FileName //load waves
	
	print filename
	
	Wave Voltage__V_, Current__A_, Luminance__cd_m2_
	Current__A_ = 1000*ABS(Current__A_)/0.1 //convert I to J in units mA/cm2, assumes 0.1 cm^2 device area (10 mm^2)
	
	Display Current__A_ vs Voltage__V_; AppendToGraph/R Luminance__cd_m2_ vs Voltage__V_
	ModifyGraph mode=4,rgb(Current__A_ )=(65535,0,0),marker(Current__A_ )=6,opaque(Current__A_ )=1;DelayUpdate
	ModifyGraph rgb(Luminance__cd_m2_)=(1,4,52428),marker(Luminance__cd_m2_)=8,opaque(Luminance__cd_m2_)=1
	ModifyGraph log(left)=1;DelayUpdate
	ModifyGraph log(right)=1;DelayUpdate
	ModifyGraph logHTrip=1;DelayUpdate
	Label left "Current Density (mA/cm\\S2\\M\\U)";DelayUpdate
	Label bottom "Voltage (V)";DelayUpdate
	Label right "Luminance (cd/m\\S2\\M\\U)"
	ModifyGraph tick=2,btLen=4
	ModifyGraph mirror(bottom)=2
	ModifyGraph alblRGB(left)=(65535,0,0)
	ModifyGraph alblRGB(right)=(1,4,52428)
	ModifyGraph mrkThick=1.2
	SetAxis right 0.5,100000
	
	string device, pixel, info
	
	prompt device, "Device Name:"
	prompt pixel, "Pixel No:"
	prompt info, "Other info to include in wavename:"
	doprompt "Wave names", device, pixel, info
	
	string device_textbox
	device_textbox = device+"_p"+pixel+"_"+info
	TextBox/C/N=text0/F=0/A=LT device_textbox
	
	string nameV, nameJ, nameL
	nameV = device+"_p"+pixel+"_"+info+"_V"
	nameJ = device+"_p"+pixel+"_"+info+"_J"
	nameL = device+"_p"+pixel+"_"+info+"_L"
	rename Voltage__V_ $nameV
	rename Current__A_ $nameJ
	rename Luminance__cd_m2_ $nameL
	
	DoWindow/C/T $(device_textbox), device_textbox
end

function load_JVL_append()

	open/R/D/T="????" fileID //get fileID
	
	String FileName
	FileName=ParseFilePath(3, S_filename, ":", 0, 0) //grabs the name of the file
	LoadWave/J/D/W/K=0/L={5,6,0,0,3} S_FileName //load waves
	
	print filename
	
	Wave Voltage__V_, Current__A_, Luminance__cd_m2_
	Current__A_ = 1000*ABS(Current__A_)/0.1 //convert I to J in units mA/cm2, assumes 0.1 cm^2 device area (10 mm^2)
	
	AppendToGraph Current__A_ vs Voltage__V_; AppendToGraph/R Luminance__cd_m2_ vs Voltage__V_
	ModifyGraph mode=4,rgb(Current__A_ )=(65535,0,0),marker(Current__A_ )=6,opaque(Current__A_ )=1;DelayUpdate
	ModifyGraph rgb(Luminance__cd_m2_)=(1,4,52428),marker(Luminance__cd_m2_)=8,opaque(Luminance__cd_m2_)=1
	ModifyGraph log(left)=1;DelayUpdate
	ModifyGraph log(right)=1;DelayUpdate
	ModifyGraph logHTrip=1;DelayUpdate
	Label left "Current Density (mA/cm\\S2\\M\\U)";DelayUpdate
	Label bottom "Voltage (V)";DelayUpdate
	Label right "Luminance (cd/m\\S2\\M\\U)"
	ModifyGraph tick=2,btLen=4
	ModifyGraph mirror(bottom)=2
	ModifyGraph alblRGB(left)=(65535,0,0)
	ModifyGraph alblRGB(right)=(1,4,52428)
	ModifyGraph mrkThick=1.2
	SetAxis right 0.5,100000
	
	string device, pixel, info
	
	prompt device, "Device Name:"
	prompt pixel, "Pixel No:"
	prompt info, "Other info to include in wavename:"
	doprompt "Wave names", device, pixel, info
	
	string device_textbox
	device_textbox = device+"_p"+pixel+"_"+info
	TextBox/C/N=text0/F=0/A=LT device_textbox
	
	string nameV, nameJ, nameL
	nameV = device+"_p"+pixel+"_"+info+"_V"
	nameJ = device+"_p"+pixel+"_"+info+"_J"
	nameL = device+"_p"+pixel+"_"+info+"_L"
	rename Voltage__V_ $nameV
	rename Current__A_ $nameJ
	rename Luminance__cd_m2_ $nameL
	
end

function ELload()

	LoadWave/J/D/W/K=0/L={22,23,0,0,0} 

end

function EQEcalc_direct()

	string ELwavelength, EL, bckgnd
	variable J //J is current density in mA/cm2
	
	prompt ELwavelength, "Select EL wavelength wave (units nm):", popup, WaveList("*",";","")
	prompt EL, "Select EL wave (units uW/nm):", popup, WaveList("*",";","")
	prompt bckgnd, "Select background wave (units uW/nm):" popup, WaveList("*",";","")
	prompt J, "Current density (units mA/cm^2):"
	
	doprompt "Initialisation", EL, ELwavelength, bckgnd, J //creates popup window
		if (V_Flag)
			return -1
		endif
			
	wave w_ELwavelength = $ELwavelength
	wave w_EL = $EL
	wave w_bckgnd = $bckgnd
	wave w_EL_lambda_INT
	variable w_EL_lambda_area
	variable Np //number of photons
	variable Ne //number of excitons
	variable EQE //EQE = Np/Ne 
	variable h = 6.63*10^(-34) //planck's constant
	variable c = 3*10^8 //speed of light
	variable e = 1.6*10^(-19) //charge of an electron
	
	variable length = DimSize(w_ELwavelength,0)
	make/n=(length) w_EL_lambda
	
	w_EL_lambda = (w_EL-w_bckgnd)*w_ELwavelength //multiply spectral power density by wavelength to get energy, first subtract bg
	Integrate w_EL_lambda/D=w_EL_lambda_INT
	w_EL_lambda_area = wavemax(w_EL_lambda_INT,380,780)
	Np = w_EL_lambda_area*(10^-9)/(h*c) //num of photons (accounts for units of nm)
	Ne = (J*10^-3*10^4)/e //num of electrons
	
	EQE = Np/Ne
	print EQE
	
	killwaves w_EL_lambda, w_EL_lambda_INT

end

function EQEcalc_lum()

	variable h = 6.63*10^(-34) //planck's constant (J.s)
	variable c = 3*10^8 //speed of light (m/s)
	variable e = 1.6*10^(-19) //charge of an electron (C, or A.s)
	make/o/n=401 zero_background = 0
	
	make/o/n=401 CIE_y=0 //CIE photopic function, data for 360-1000nm follows (commented out):
	//CIE_y[0]= {3.917e-06,4.394e-06,4.93e-06,5.532e-06,6.208e-06,6.965e-06,7.813e-06,8.767e-06,9.84e-06,1.104e-05,1.239e-05,1.389e-05,1.556e-05,1.744e-05,1.958e-05,2.202e-05,2.484e-05,2.804e-05,3.153e-05,3.522e-05}
	//CIE_y[20]= {3.9e-05,4.283e-05,4.691e-05,5.159e-05,5.718e-05,6.4e-05,7.234e-05,8.221e-05,9.351e-05,0.0001061,0.00012,0.000135,0.0001515,0.0001702,0.0001918,0.000217,0.0002469,0.0002812,0.0003185,0.0003573}
	//CIE_y[40]= {0.000396,0.0004337,0.000473,0.0005179,0.0005722,0.00064,0.0007246,0.0008255,0.0009412,0.00107,0.00121,0.001362,0.001531,0.00172,0.001935,0.00218,0.002455,0.002764,0.003118,0.003526,0.004,0.004546}
	//CIE_y[62]= {0.005159,0.005829,0.006546,0.0073,0.008087,0.008909,0.009768,0.01066,0.0116,0.01257,0.01358,0.01463,0.01572,0.01684,0.01801,0.01921,0.02045,0.02172,0.023,0.02429,0.02561,0.02696,0.02835,0.0298}
	//CIE_y[86]= {0.03131,0.03288,0.03452,0.03623,0.038,0.03985,0.04177,0.04377,0.04584,0.048,0.05024,0.05257,0.05498,0.05746,0.06,0.0626,0.06528,0.06804,0.07091,0.0739,0.07702,0.08027,0.08367,0.08723,0.09098}
	//CIE_y[111]= {0.09492,0.09905,0.1034,0.1079,0.1126,0.1175,0.1227,0.128,0.1335,0.139,0.1447,0.1505,0.1565,0.1627,0.1693,0.1762,0.1836,0.1913,0.1994,0.208,0.2171,0.2267,0.2369,0.2475,0.2586,0.2702,0.2823,0.2951}
	//CIE_y[139]= {0.3086,0.323,0.3384,0.3547,0.3717,0.3893,0.4073,0.4256,0.4443,0.4634,0.4829,0.503,0.5236,0.5445,0.5657,0.587,0.6082,0.6293,0.6503,0.6709,0.6908,0.71,0.7282,0.7455,0.762,0.7778,0.7932,0.8081}
	//CIE_y[167]= {0.8225,0.8363,0.8495,0.862,0.8738,0.885,0.8955,0.9054,0.9149,0.9237,0.9321,0.9399,0.9472,0.954,0.9603,0.966,0.9713,0.976,0.9803,0.9841,0.9874,0.9903,0.9928,0.995,0.9967,0.9981,0.9991,0.9997}
	//CIE_y[195]= {1,0.9999,0.9993,0.9983,0.9969,0.995,0.9926,0.9897,0.9864,0.9827,0.9786,0.9741,0.9692,0.9639,0.9581,0.952,0.9455,0.9385,0.9312,0.9235,0.9154,0.907,0.8983,0.8892,0.8798,0.87,0.8599,0.8494,0.8386}
	//CIE_y[224]= {0.8276,0.8163,0.8048,0.7931,0.7812,0.7692,0.757,0.7448,0.7324,0.72,0.7075,0.6949,0.6822,0.6695,0.6567,0.6438,0.631,0.6182,0.6053,0.5925,0.5796,0.5668,0.554,0.5411,0.5284,0.5156,0.503,0.4905}
	//CIE_y[252]= {0.478,0.4657,0.4534,0.4412,0.4291,0.417,0.405,0.393,0.381,0.3689,0.3568,0.3448,0.3328,0.321,0.3093,0.2979,0.2866,0.2756,0.265,0.2548,0.2449,0.2353,0.2261,0.217,0.2082,0.1995,0.1912,0.183,0.175}
	//CIE_y[281]= {0.1672,0.1596,0.1523,0.1451,0.1382,0.1315,0.125,0.1188,0.1128,0.107,0.1015,0.09619,0.09112,0.08626,0.0816,0.07712,0.07283,0.06871,0.06477,0.061,0.0574,0.05396,0.05067,0.04755,0.04458,0.04176}
	//CIE_y[307]= {0.03908,0.03656,0.0342,0.032,0.02996,0.02808,0.02633,0.02471,0.0232,0.0218,0.0205,0.01928,0.01812,0.017,0.0159,0.01484,0.01381,0.01283,0.01192,0.01107,0.01027,0.009533,0.008846,0.00821,0.007624}
	//CIE_y[332]= {0.007085,0.006591,0.006138,0.005723,0.005343,0.004996,0.004676,0.00438,0.004102,0.003838,0.003589,0.003354,0.003134,0.002929,0.002738,0.00256,0.002393,0.002237,0.002091,0.001954,0.001825,0.001704}
	//CIE_y[354]= {0.00159,0.001484,0.001384,0.001291,0.001204,0.001123,0.001047,0.0009766,0.0009111,0.0008501,0.0007932,0.00074,0.0006901,0.0006433,0.0005995,0.0005585,0.00052,0.0004839,0.0004501,0.0004183,0.0003887}
	//CIE_y[375]= {0.0003611,0.0003354,0.0003114,0.0002892,0.0002685,0.0002492,0.0002313,0.0002147,0.0001993,0.000185,0.0001719,0.0001598,0.0001486,0.0001383,0.0001288,0.00012,0.0001119,0.0001043,9.734e-05,9.085e-05}
	//CIE_y[395]= {8.48e-05,7.915e-05,7.386e-05,6.892e-05,6.43e-05,6e-05,5.598e-05,5.223e-05,4.872e-05,4.545e-05,4.24e-05,3.956e-05,3.692e-05,3.445e-05,3.215e-05,3e-05,2.799e-05,2.611e-05,2.436e-05,2.272e-05}
	//CIE_y[415]= {2.12e-05,1.978e-05,1.845e-05,1.722e-05,1.606e-05,1.499e-05,1.399e-05,1.305e-05,1.218e-05,1.136e-05,1.06e-05,9.886e-06,9.217e-06,8.592e-06,8.009e-06,7.466e-06,6.96e-06,6.488e-06,6.049e-06,5.639e-06}
	//CIE_y[435]= {5.258e-06,4.902e-06,4.57e-06,4.26e-06,3.972e-06,3.703e-06,3.452e-06,3.218e-06,3e-06,2.797e-06,2.608e-06,2.431e-06,2.267e-06,2.113e-06,1.97e-06,1.837e-06,1.712e-06,1.596e-06,1.488e-06,1.387e-06}
	//CIE_y[455]= {1.293e-06,1.206e-06,1.124e-06,1.048e-06,9.771e-07,9.109e-07,8.493e-07,7.917e-07,7.381e-07,6.881e-07,6.415e-07,5.981e-07,5.576e-07,5.198e-07,4.846e-07,4.518e-07}
  	
  	//data on smaller range from 380-780nm:
  	
  	CIE_y[0]= {3.9e-05,4.283e-05,4.691e-05,5.159e-05,5.718e-05,6.4e-05,7.234e-05,8.221e-05,9.351e-05,0.0001061,0.00012,0.000135,0.0001515,0.0001702,0.0001918,0.000217,0.0002469,0.0002812,0.0003185,0.0003573}
	CIE_y[20]= {0.000396,0.0004337,0.000473,0.0005179,0.0005722,0.00064,0.0007246,0.0008255,0.0009412,0.00107,0.00121,0.001362,0.001531,0.00172,0.001935,0.00218,0.002455,0.002764,0.003118,0.003526,0.004,0.004546}
	CIE_y[42]= {0.005159,0.005829,0.006546,0.0073,0.008087,0.008909,0.009768,0.01066,0.0116,0.01257,0.01358,0.01463,0.01572,0.01684,0.01801,0.01921,0.02045,0.02172,0.023,0.02429,0.02561,0.02696,0.02835,0.0298}
	CIE_y[66]= {0.03131,0.03288,0.03452,0.03623,0.038,0.03985,0.04177,0.04377,0.04584,0.048,0.05024,0.05257,0.05498,0.05746,0.06,0.0626,0.06528,0.06804,0.07091,0.0739,0.07702,0.08027,0.08367,0.08723,0.09098}
 	CIE_y[91]= {0.09492,0.09905,0.1034,0.1079,0.1126,0.1175,0.1227,0.128,0.1335,0.139,0.1447,0.1505,0.1565,0.1627,0.1693,0.1762,0.1836,0.1913,0.1994,0.208,0.2171,0.2267,0.2369,0.2475,0.2586,0.2702,0.2823,0.2951}
	CIE_y[119]= {0.3086,0.323,0.3384,0.3547,0.3717,0.3893,0.4073,0.4256,0.4443,0.4634,0.4829,0.503,0.5236,0.5445,0.5657,0.587,0.6082,0.6293,0.6503,0.6709,0.6908,0.71,0.7282,0.7455,0.762,0.7778,0.7932,0.8081}
	CIE_y[147]= {0.8225,0.8363,0.8495,0.862,0.8738,0.885,0.8955,0.9054,0.9149,0.9237,0.9321,0.9399,0.9472,0.954,0.9603,0.966,0.9713,0.976,0.9803,0.9841,0.9874,0.9903,0.9928,0.995,0.9967,0.9981,0.9991,0.9997}
	CIE_y[175]= {1,0.9999,0.9993,0.9983,0.9969,0.995,0.9926,0.9897,0.9864,0.9827,0.9786,0.9741,0.9692,0.9639,0.9581,0.952,0.9455,0.9385,0.9312,0.9235,0.9154,0.907,0.8983,0.8892,0.8798,0.87,0.8599,0.8494,0.8386}
 	CIE_y[204]= {0.8276,0.8163,0.8048,0.7931,0.7812,0.7692,0.757,0.7448,0.7324,0.72,0.7075,0.6949,0.6822,0.6695,0.6567,0.6438,0.631,0.6182,0.6053,0.5925,0.5796,0.5668,0.554,0.5411,0.5284,0.5156,0.503,0.4905}
	CIE_y[232]= {0.478,0.4657,0.4534,0.4412,0.4291,0.417,0.405,0.393,0.381,0.3689,0.3568,0.3448,0.3328,0.321,0.3093,0.2979,0.2866,0.2756,0.265,0.2548,0.2449,0.2353,0.2261,0.217,0.2082,0.1995,0.1912,0.183,0.175}
	CIE_y[261]= {0.1672,0.1596,0.1523,0.1451,0.1382,0.1315,0.125,0.1188,0.1128,0.107,0.1015,0.09619,0.09112,0.08626,0.0816,0.07712,0.07283,0.06871,0.06477,0.061,0.0574,0.05396,0.05067,0.04755,0.04458,0.04176}
	CIE_y[287]= {0.03908,0.03656,0.0342,0.032,0.02996,0.02808,0.02633,0.02471,0.0232,0.0218,0.0205,0.01928,0.01812,0.017,0.0159,0.01484,0.01381,0.01283,0.01192,0.01107,0.01027,0.009533,0.008846,0.00821,0.007624}
  	CIE_y[312]= {0.007085,0.006591,0.006138,0.005723,0.005343,0.004996,0.004676,0.00438,0.004102,0.003838,0.003589,0.003354,0.003134,0.002929,0.002738,0.00256,0.002393,0.002237,0.002091,0.001954,0.001825,0.001704}
	CIE_y[334]= {0.00159,0.001484,0.001384,0.001291,0.001204,0.001123,0.001047,0.0009766,0.0009111,0.0008501,0.0007932,0.00074,0.0006901,0.0006433,0.0005995,0.0005585,0.00052,0.0004839,0.0004501,0.0004183,0.0003887}
	CIE_y[355]= {0.0003611,0.0003354,0.0003114,0.0002892,0.0002685,0.0002492,0.0002313,0.0002147,0.0001993,0.000185,0.0001719,0.0001598,0.0001486,0.0001383,0.0001288,0.00012,0.0001119,0.0001043,9.734e-05,9.085e-05}
	CIE_y[375]= {8.48e-05,7.915e-05,7.386e-05,6.892e-05,6.43e-05,6e-05,5.598e-05,5.223e-05,4.872e-05,4.545e-05,4.24e-05,3.956e-05,3.692e-05,3.445e-05,3.215e-05,3e-05,2.799e-05,2.611e-05,2.436e-05,2.272e-05}
	CIE_y[395]= {2.12e-05,1.978e-05,1.845e-05,1.722e-05,1.606e-05,1.499e-05}


	//user selects waves from drop list

	string device, voltage, J_V, L_V, EL, ELwavelength, ELbckgnd
	variable lum_noise = 1
	
	prompt device, "Device/pixel name:"
	prompt ELwavelength, "Select EL wavelength wave (units nm):", popup, WaveList("*",";","")
	prompt EL, "Select EL wave (units uW/nm):", popup, WaveList("*",";","")
	prompt ELbckgnd, "Select background wave (units uW/nm):" popup, WaveList("*",";","")
	prompt J_V, "Select current density wave (units mA/cm^2):" popup, WaveList("*",";","")
	prompt L_V, "Select luminance wave (units cd/m^2):" popup, WaveList("*",";","")
	prompt voltage, "Select voltage wave (units V):" popup, WaveList("*",";","")
	prompt lum_noise, "Enter noise threshold of luminance:"
		
	doprompt "Initialisation", device, EL, ELwavelength, ELbckgnd, voltage, J_V, L_V, lum_noise //creates popup window
		if (V_Flag)
			return -1
		endif

	//set up all the required waves by linking them to selected waves

	wave w_ELwavelength = $ELwavelength
	wave w_EL = $EL
	wave w_ELbckgnd = $ELbckgnd
	wave w_voltage = $voltage
	wave w_J_V = $J_V
	wave w_L_V_original = $L_V
	variable length = DimSize(w_voltage,0)	 //length of the J,V,L data dictates length of all efficiency waves
	
	variable lengthEL = DimSize(w_EL,0)		//length of EL wave
	variable WLstart = w_ELwavelength[0]		//first wavelength of EL wave
	variable WLend = WLstart + lengthEL - 1	//final wavelength of EL wave - assumes data increment is 1 nm
	
	
	//remove noise from luminance wave (anything below lum_noise cd/m2 becomes zero)
	duplicate w_L_V_original w_L_V
	Variable n=0 						//initialise loop counter variable
	for (n=0; n < length; n+=1)
		if (w_L_V[n] < lum_noise)
			w_L_V[n] = 0 			//remove noise by setting value to 0
		endif
	endfor
		
	make/o/n=(length) w_Np =0 		//number of photons
	make/o/n=(length) w_Ne =0 		//number of electrons
	make/o/n=(length) w_EQE			 //EQE = Np/Ne
	make/o/n=(length) w_J_eff 			//current efficiecy in cd/A
	make/o/n=(length) w_P_eff			 //power efficiency in lm/W 

	//First calculate the integrals required for Np and Ne 

	make/o/n=401 w_EL_lambda 	//multiplication of spectral power density and wavelength (for conversion to energy)
	w_EL_lambda = ((w_EL-w_ELbckgnd)/wavemax(w_EL))*w_ELwavelength 	//first subtract bg, normalise, then multiply waves
	wave w_EL_lambda_INT 	//integral creates a wave of cumulative area
	variable EL_lambda_area 	//area is a variable
	Integrate w_EL_lambda/D=w_EL_lambda_INT
	EL_lambda_area = wavemax(w_EL_lambda_INT,380,780) 	//max of integral wave is area, selecting max rather than value at 780 to avoid noise errors
	
	make/o/n=401 w_EL_CIE
	w_EL_CIE = ((w_EL-w_ELbckgnd)/wavemax(w_EL))*CIE_y 	//multiplication of CIE photopic function and EL intensity data (converts to luminance)
	wave w_EL_CIE_INT	 	//integral 
	variable EL_CIE_area 		//area 
	Integrate w_EL_CIE/D=w_EL_CIE_INT
	EL_CIE_area = wavemax(w_EL_CIE_INT,380,780) 		//max of integral wave is area, selecting max rather than value at 780 to avoid noise errors  
	
	print EL_CIE_area
	print EL_lambda_area
	
	//calculate Np, Ne, and EQE
	
	w_Np = (10^(-9))*Pi*(w_L_V)*(EL_lambda_area)/(683*h*c*(EL_CIE_area))
	w_Ne = (10^(-3))*(10^4)*(w_J_V)/e
	w_EQE = 100*(w_Np)/(w_Ne)
	
	//calculate current efficiency (J_eff) and power efficiency (P_eff)
	w_J_eff = (w_L_V)/((10^(-3))*(10^4)*(w_J_V))
	w_P_eff = Pi*(w_J_eff)/(w_voltage)

// following code is obsolete (added an earlier loop to set minimum luminance)	
//	//extract peak EQE, J_eff, and P_eff with user-defined minimum luminance to remove noise (recommended value ~4)
//	variable min_lum = lum_noise
//	make/o/n=3 w_max_eff
//	make/o/T/n=3 max_eff_names
//	max_eff_names[0] = "EQE"
//	max_eff_names[1] = "Current Efficiency cd/A"
//	max_eff_names[2] = "Power efficiency lm/W"
//	prompt min_lum "Set minimum luminance for peak efficiency values (if different to noise threshold):"
//	doprompt "Set minimum luminance", min_lum //creates popup window
//		if (V_Flag)
//			return -1
//		endif
//	
//	variable trigger=0 
//	variable p_min_lum = 0					//trigger when luminance reaches user value
//	for (n=0; trigger<1; n+=1)
//		if (w_L_V[n] > min_lum)
//			trigger=1 			//loop will end when lum is > min_lum
//			p_min_lum = n
//		endif
//	endfor	
//	
//	w_max_eff[0] = wavemax(w_EQE, p_min_lum, (length-1)) //max of wave between p_min_lum and last point
//	w_max_eff[1] = wavemax(w_J_eff, p_min_lum, (length-1)) 
//	w_max_eff[2] = wavemax(w_P_eff,p_min_lum, (length-1)) 
//	edit max_eff_names, w_max_eff
	
	string EQE, J_eff, P_eff, lumwave//, max_eff
	EQE = device + "_EQE"
	J_eff = device + "_J_eff"
	P_eff = device + "_P_eff"
//	max_eff = "max_eff_"+device
			
//	display w_EQE, w_J_eff, w_P_eff vs w_voltage
//		DoWindow/C/T $(device+"eff_V"), device+"_efficiency_V"
//		ModifyGraph tick=2,mirror=2,standoff=0,btLen=5,mode=3,marker=8,mrkThick=1.2,opaque=1,lsize=1.2;DelayUpdate
//		Label bottom "Voltage (V)"
//		ModifyGraph rgb(w_J_eff)=(0,0,65280), rgb(w_P_eff)=(0,39168,0)
//		Legend/C/N=text0/A=MC
		
	display w_EQE, w_J_eff, w_P_eff vs w_J_V
		DoWindow/C/T $(device+"eff_J"), device+"_efficiency_J"
		ModifyGraph tick=2,mirror=2,standoff=0,btLen=5,log(bottom)=1,mode=3,marker=8,mrkThick=1.2,opaque=1,lsize=1.2;DelayUpdate
		Label bottom "Current density (mA/cm\S2\M)"
		ModifyGraph rgb(w_J_eff)=(0,0,65280), rgb(w_P_eff)=(0,39168,0)
		Legend/C/N=text0/A=MC
		
	display w_EQE, w_J_eff, w_P_eff vs w_L_V_original
		DoWindow/C/T $(device+"eff_L"), device+"_efficiency_L"
		ModifyGraph tick=2,mirror=2,standoff=0,btLen=5,log(bottom)=1,mode=3,marker=8,mrkThick=1.2,opaque=1,lsize=1.2;DelayUpdate
		Label bottom "Luminance (cd/m\S2\M)"
		ModifyGraph rgb(w_J_eff)=(0,0,65280), rgb(w_P_eff)=(0,39168,0)
		Legend/C/N=text0/A=MC
		
	//tidy up
	rename w_EQE $EQE
	rename w_J_eff $J_eff
	rename w_P_eff $P_eff
//	rename w_max_eff $max_eff
	killwaves w_Np, w_Ne, w_EL_Lambda, w_EL_lambda_INT, w_EL_CIE, w_EL_CIE_INT, w_L_V
	
end


function compare_efficiency_max()		//compares the max efficiency of devices

	variable Ns, i, n, length, min_lum
	string lum, eff, maxname

	prompt maxname, "Enter name of variable to maximise:"
	prompt Ns, "Enter number of samples:"
	prompt min_lum, "Enter minimum luminace (noise):"

	doprompt "Please specify", maxname, Ns, min_lum
		if (V_Flag)
			return -1
		endif	

	make/o/n=(Ns)/O/T w_device
	make/o/n=(Ns)/O w_max_eff

	for (i=0; i<Ns; i+=1)

		prompt lum, "Select luminance wave:", popup, WaveList("*",";","")
		prompt eff, "Select efficiency wave:", popup, WaveList("*",";","")
	
			doprompt "Select Sample Waves", lum, eff
				if (V_Flag)
					return -1
				endif
		wave w_lum = $lum
		wave w_eff = $eff
	
		variable trigger=0 
		variable p_min_lum = 0					//trigger when luminance reaches user value
			for (n=0; trigger<1; n+=1)
				if (w_lum[n] > min_lum)
					trigger=1 			//loop will end when lum is > min_lum
					p_min_lum = n
				endif
			endfor	
		
		length = DimSize(w_lum,0)
		
		w_max_eff[i] = wavemax(w_eff, p_min_lum, (length-1)) //max of wave between p_min_lum and last point
		w_device[i] = eff
	
	endfor

	string name1 = "max_"+maxname
	string name2 = "device_name"

	edit w_device w_max_eff

	rename w_max_eff $name1
	rename w_device $name2

end

function compare_efficiency_select()

	variable Ns, i, n, length, cden, p_cden
	string J, eff, maxname

	prompt maxname, "Enter name of efficiency variable:"
	prompt Ns, "Enter number of samples:"
	prompt cden, "Enter curent density:"

	doprompt "Compare efficiencies", maxname, Ns, cden
		if (V_Flag)
			return -1
		endif	

	make/o/n=(Ns)/O/T w_device
	make/o/n=(Ns)/O w_select_eff

	for (i=0; i<Ns; i+=1)

		prompt J, "Select current density wave:", popup, WaveList("*",";","")
		prompt eff, "Select efficiency wave:", popup, WaveList("*",";","")
	
		doprompt "Select Sample Waves", J, eff
			if (V_Flag)
				return -1
			endif
		wave w_J = $J
		wave w_eff = $eff
	
		length = DimSize(w_J,0) //length of current wave - required so that loop won't go forever
		
		variable error = 0
		variable trigger=0 		//trigger when cden reaches user value
			for (n=0; trigger<1; n+=1)
				if (n<length)			//end condition 1: length of wave reached (when n = length)
					if (w_J[n] > cden)
						trigger=1 		//end condition 2:  w_J is greater than cden
						p_cden = (cden-w_J[n])/(w_J[n]-w_J[n-1])+n	//linear interpolation of likely "real point" of cden from values either side of cden
					endif
				else
					trigger = 1 //if length exceeded
					error = 1	//flag error
				endif	
			endfor			
		
		length = DimSize(w_J,0)
		
		if (error == 0)
			w_select_eff[i] = w_eff[p_cden]	//if no error, assign value 
		else
			error = 0							//if error, don't assign value, reset error to 0
		endif
		
		w_device[i] = eff						//assign name 
	
	endfor

	string name1 = maxname+"_at_"+num2str(cden)+"mAcm2"
	string name2 = "device_name"

	edit w_device w_select_eff

	rename w_select_eff $name1
	rename w_device $name2

end

function compare_efficiency_selectlum()

	variable Ns, i, n, length, lum, p_lum
	string L, eff, maxname

	prompt maxname, "Enter name of efficiency variable:"
	prompt Ns, "Enter number of samples:"
	prompt lum, "Enter luminance density:"

	doprompt "Compare efficiencies", maxname, Ns, lum
		if (V_Flag)
			return -1
		endif	

	make/o/n=(Ns)/O/T w_device
	make/o/n=(Ns)/O w_select_eff

	for (i=0; i<Ns; i+=1)

		prompt L, "Select luminance wave:", popup, WaveList("*",";","")
		prompt eff, "Select efficiency wave:", popup, WaveList("*",";","")
	
		doprompt "Select Sample Waves", L, eff
			if (V_Flag)
				return -1
			endif
		wave w_L = $L
		wave w_eff = $eff
	
		length = DimSize(w_L,0) //length of luminance wave - required so that loop won't go forever
		
		variable error = 0
		variable trigger=0 		//trigger when luminance reaches user value
			for (n=0; trigger<1; n+=1)
				if (n<length)			//end condition 1: length of wave reached (when n = length)
					if (w_L[n] > lum)
						trigger=1 		//end condition 2:  w_L is greater than cden
						p_lum = (lum-w_L[n])/(w_L[n]-w_L[n-1])+n	//linear interpolation of likely "real point" of lum from values either side of lum
					endif
				else
					trigger = 1 //if length exceeded
					error = 1	//flag error
				endif	
			endfor			
		
		length = DimSize(w_L,0)
		
		if (error == 0)
			w_select_eff[i] = w_eff[p_lum]	//if no error, assign value 
		else
			error = 0							//if error, don't assign value, reset error to 0
		endif
		
		w_device[i] = eff						//assign name 
	
	endfor

	string name1 = maxname+"_at_"+num2str(lum)+"cd/m2"
	string name2 = "device_name"

	edit w_device w_select_eff

	rename w_select_eff $name1
	rename w_device $name2

end

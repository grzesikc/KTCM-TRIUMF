module KCM_LOGIC(
//DEFINE INPUTS AND OUTPUT names
input wire [1:0] KEY ,

output wire	    [7:0]		LED,
//////////// SW //////////
input wire		 [3:0]		SW,
//////////// GPIO_0, GPIO connect to GPIO Default //////////
inout wire	    [35:0]		GPIO_0,
//////////// GPIO_1, GPIO connect to GPIO Default //////////
output wire	    [35:0]		GPIO_1,

output wire		          	ADC_CONVST,
output wire          		ADC_SCK,
output wire	          		ADC_SDI,
input wire	          		ADC_SDO,
	//////////// CLOCK //////////
input wire	          		FPGA_CLK1_50,
input wire	          		FPGA_CLK2_50,
input wire	          		FPGA_CLK3_50,
output wire NewData,
output wire [11:0] ADCValue,
output wire [17:0] ADCTime,
output wire [17:0] currentTrigOffset,
output wire [11:0] highVoltage,
output wire [17:0] meanOffset,
output wire CLOCK_80MHZ

);










//TEST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
reg signal1,signal2;
reg [3:0] pulse1state;
reg [3:0] pulse2state;
reg [3:0] pulse1;
reg [3:0] pulse2;
reg resetsig1,resetsig2;
reg [16:0] counter1;
reg [16:0] counter2;
always @(*)
begin
	case(pulse1)
	record1State:begin
		signal1 = 0;
		if (counter1 == 17'd80000)
		begin
			resetsig1 = 1;
			pulse1state = record2State;
		end
		else
		begin
			pulse1state = record1State;
			resetsig1 = 0;
		end
	end
	record2State:begin
		signal1 = 1;
		resetsig1 = 0;
		if(counter1 == 17'd72000)
		begin
			pulse1state = record1State;
		end
		else
			pulse1state = record2State;
	end
	default:begin
		pulse1state = record2State;
	end
	endcase
end
always @(*)
begin
	case(pulse2)
	beginState:begin
	signal2 = 0;
	if( counter1 == 17'd16000)
	begin
	resetsig2 = 1;
	pulse2state = record2State;
	end
	
	else
	begin
	pulse2state = beginState;
	resetsig2 = 0;
	end
	
	end
	record1State:begin
	signal2 = 0;
	if (counter2 == 17'd80000)
	begin
	resetsig2 = 1;
	pulse2state = record2State;
	end
	else
	begin
	pulse2state = record1State;
	resetsig2 = 0;
	end
	end
	record2State:begin
	signal2 = 1;
	resetsig2 = 0;
	if(counter2 == 17'd72000)
	begin
	pulse2state = record1State;
	end
	else
	pulse2state = record2State;
	end
	default:begin
	pulse2state = beginState;
	end
	endcase
end

always@(posedge CLOCK_80MHZ)
begin
pulse1 <= pulse1state;
pulse2 <= pulse2state;

if(resetsig1)
counter1 <= 17'd0;
else
counter1 <= counter1 + 17'd1;

if(resetsig2)
counter2 <= 17'd0;
else
counter2 <= counter2 + 17'd1;
end


//TEST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11



















wire [23:0] RESULT_CHAN [0:1] ;
wire [23:0] I_PLUS_Q;
wire [11:0] CHAN [0:7];
wire KEY_NOT;
wire RESET_80MHZ;
assign KEY_NOT = !KEY[0];

	DE0_80MHZ u1 (
		.ref_clk_clk        (FPGA_CLK1_50),        //      ref_clk.clk
		.ref_reset_reset    (KEY_NOT),    //    ref_reset.reset
		.sys_clk_clk        (CLOCK_80MHZ),        //      sys_clk.clk
		.reset_source_reset (RESET_80MHZ)  // reset_source.reset
	);


    ADC_LTC u0 (
        .ADC_SCLK  (ADC_SCK),  // adc_signals.SCLK
        .ADC_CS_N  (ADC_CONVST),  //            .CS_N
        .ADC_SDAT  (ADC_SDO),  //            .SDAT
        .ADC_SADDR (ADC_SDI), //            .SADDR
        .CLOCK     (CLOCK_80MHZ),     //         clk.clk
        .CH0       (CHAN[0]),       //    readings.CH0
        .CH1       (CHAN[1]),       //            .CH1
        .CH2       (CHAN[2]),       //            .CH2
        .CH3       (CHAN[3]),       //            .CH3
        .CH4       (CHAN[4]),       //            .CH4
        .CH5       (CHAN[5]),       //            .CH5
        .CH6       (CHAN[6]),       //            .CH6
        .CH7       (CHAN[7]),		  //            .CH7
		  .done      (done),
        .RESET     (KEY_NOT)      //       reset.reset
    );

reg [11:0] NEWADCVALUE [0:1];
wire [12:0] IQRemainder;
wire done;
reg [17:0] ADCTimeR;
assign NewData = done;
//assign ADCValue = IQValue;

wire [11:0] IQvalue;
assign ADCValue = CHAN[0];
	
SQUARER	SQUARER_inst1 (
	.dataa ( CHAN[0]),
	.result ( RESULT_CHAN[0] )
	);
	
SQUARER SQUARER_inst2(
	.dataa ( CHAN[1] ),
	.result ( RESULT_CHAN[1] )
	);
	
assign I_PLUS_Q = CHAN[0] + CHAN[1];

SQRT	SQRT_inst (
	.radical ( I_PLUS_Q ),
	.q ( IQvalue ),
	.remainder ( IQRemainder )
	);

always@(posedge CLOCK_80MHZ)
begin
//ADCTimeR <= TrigTime;//move after test
	if(done)
	ADCTimeR <= TrigTime;
	
end
assign ADCTime = TrigTime;
assign currentTrigOffset = triggerOffset[datanum];
//=======================================================
//  REG/WIRE declarations
//=======================================================
//reg  [31:0]	Cont;
//reg [11:0] COMPARE;
reg [7:0] LEDr;
reg GPIOr;

// FOR ADC SIGNAL*****************************
reg [23:0] sumAveraging;
reg [18:0] meanPeriod;
reg [17:0] pulseSize;
reg [13:0] valleySize;
reg [17:0] pulseAveraging [0:31];
reg [13:0] valleyAveraging [0:31];
reg [5:0] datanum;
reg countPulseStart;
reg countValleyStart;
reg countValley;
reg countPulse;
reg writeData,writeValleySum,writePulseSum;
reg dataReady;
reg [3:0] state;
reg [3:0] nextState;
reg ADCsignal;

// FOR PULSER SIGNAL*************************
reg pulserSignal;
reg [23:0] PsumAveraging;
reg [18:0] PmeanPeriod;
reg [17:0] PpulseSize;
reg [13:0] PvalleySize;
reg [17:0] PpulseAveraging [0:31];
reg [13:0] PvalleyAveraging [0:31];
reg [5:0] Pdatanum;
reg PcountPulseStart;
reg PcountValleyStart;
reg PcountValley; // With P denotes that they are for the pulser signal. follows same logic.
reg PcountPulse;
reg PwriteData,PwriteValleySum,PwritePulseSum;
reg PdataReady;
reg [3:0] Pstate;
reg [3:0] PnextState;

//etc*******************************
reg [17:0] triggerOffset [0:31];
reg [23:0] triggerSum;
reg [17:0] meanTriggerOffset;

assign meanOffset = meanTriggerOffset;

//Triggering parameters
reg [3:0] Tstate;
reg [3:0] TnextState;
reg TriggerSignal;
reg TdataReady;
reg BeamOn;
reg [6:0] OnRatio;
reg [6:0] OffRatio;
reg [6:0] switchCount;
reg resetSwitchCount;
reg turnON;
reg turnOFF;
reg resetButton;
reg [5:0]Tdatanum;
reg [17:0]TrigTime;
reg [17:0] errorClockSize;
reg errorReset;
reg errorMessageComplete;
reg error;
//interger k;
//wire runTrigger;
reg [11:0]meanHighVoltage;
reg [18:0]highVoltageSum;
reg [6:0]countHV;
assign highVoltage = meanHighVoltage;

parameter COMPARE = 12'b011111111111, resetState=4'd0, beginState=4'd1,record1State=4'd2,record2State=4'd3;

parameter KickerOnState=4'd2, KickerOffState=4'd3, errorLowState=4'd4, errorHighState=4'd5;
//=======================================================
//  Intitial Values
//=======================================================
initial
begin
datanum <= 6'd32; 
Tdatanum <= 6'd4;
dataReady <= 1'b0;
sumAveraging <= 23'd0;
Pdatanum <= 6'd32; 
PdataReady <= 1'b0;
TdataReady = 1'b0;
PsumAveraging <= 23'd0;
error <= 1'b0;
Pstate <= resetState;
state <= resetState;
Tstate <= resetState;
TnextState <= resetState;

pulse2state <= beginState;
pulse1state <= record2State;
pulse1 <= record2State;
pulse2 <= beginState;

resetSwitchCount <= 1'b0;
resetButton <=1'b0;
OnRatio <= 7'd1;
OffRatio <= 7'd2;
switchCount <=7'd1;

highVoltageSum<=12'd0;
//for (k = 6'd0; k < 6'd32 ; k = (k + 6'd1))
//begin
//pulseAveraging[k[4:0]] = 18'd0;
//valleyAveraging[k[4:0]] = 14'd0;
//end 
end
//assign GPIO_0  		=	36'hzzzzzzzz;
//assign GPIO_1  		=	36'hzzzzzzzz;

//=======================================================
//  conditions for different outputs. Mainly for FPGA program analysis
//=======================================================
always@(posedge CLOCK_80MHZ)
    begin
      case (SW)
		0:LEDr =	KEY[1]? {CHAN[0][11:4]}:8'hff;
		1:LEDr = KEY[1]? {IQvalue[11:4]}:8'hff;
		5:LEDr = KEY[1]? {(CHAN[0]>COMPARE),(CHAN[0]<COMPARE),6'd0}:8'hff;
		2:LEDr = KEY[1]? {CHAN[1][11:4]}:8'hff;
		3:begin
		GPIOr = CHAN[0]>COMPARE;
		LEDr = KEY[1]? {(CHAN[0]>COMPARE),(CHAN[0]<COMPARE),6'd0}:8'hff;
		end
		4:LEDr =	KEY[1]? {CHAN[0][7:0]}:8'hff;
		//5:
		//6:
		//7:
		8:begin
		//	runTrigger =1'b1;
			LEDr= KEY[1]? {pulseSize[17:10]}:8'hff;
		end
		default:begin
		GPIOr = 1'hz;
		LEDr = 8'hff;
		end
		endcase
    end
	 
assign LED = LEDr;
assign GPIO_0[0] = GPIOr;
//assign GPIO_0[2] = CLOCK_80MHZ;
assign GPIO_0[35:4] = 34'hzzzzzzzz;

always@(posedge CLOCK_80MHZ)
begin
	if(errorReset)
	begin
		state <= resetState;
		Pstate <= resetState;
		Tstate <= resetState;
	end
	else
	begin
		state <= nextState;
		Pstate <= PnextState;
		Tstate <= TnextState;
	end
end

//***********************ADC SIGNAL ANALYSIS**********************

//=======================================================
// State conditions for the measurment of the ADC pulse signal.
// Determines if ADC value is above a threshold, and sets the state accordingly.
//=======================================================
always @(*)
begin
		ADCsignal <= signal2;//ADCsignal <= GPIO_0[2];
		case(state)
		resetState:begin
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			countPulseStart=0;
			if(ADCsignal==1'b0 && (Pstate==record1State||Pstate==record2State))//if(CHAN0>COMPARE)
				nextState = beginState;
			else
				nextState = resetState;
		end
		beginState:begin
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			if(ADCsignal && (Pstate==record1State||Pstate==record2State))//if(CHAN0>COMPARE && (Pstate==record1State||Pstate==record2State))
				begin
				nextState = record1State;
				countPulseStart=1;
				end
			else
			begin
				nextState = beginState;
				countPulseStart=0;
			end
		end
		record1State:begin
			countValley=0;
			countPulse=1;
			countPulseStart=0;
			if(ADCsignal==1'b0)//if(CHAN0<COMPARE)
			begin
				nextState = record2State; 
				countValleyStart=1;
			end
			else
			begin
				nextState = record1State;
				countValleyStart=0;
			end
		end
		record2State:begin
			countValley=1;
			countPulse=0;
			countValleyStart=0;
			if(ADCsignal)//if(CHAN0>COMPARE)
			begin
				nextState = record1State;
				countPulseStart=1;
			end
			else
			begin
				nextState = record2State;
				countPulseStart=0;
			end
		end
		default:begin
			countValley=0;
			countPulse=0;
			nextState = resetState;
		end
		endcase
end

//=======================================================
//counter for the valley time interval of the ADC signal(beam OFF)
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	if(countValleyStart==1)
		valleySize <= 14'd0;
	else if(countValley==1)
		valleySize <= valleySize + 14'd1;
end

//always@(posedge CLOCK_80MHZ)
//begin
//if(CHAN0 == PrevCHAN0)
//
//else
//	PrevCHAN0 <= CHAN0;
//	
//end

//=======================================================
//counter for the pulse time interval of the ADC signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(countPulseStart==1)
		pulseSize <= 18'd0;
	else if(countPulse==1)
		pulseSize <= pulseSize + 18'd1;
end

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(writeValleySum) 
		begin
			valleyAveraging [datanum] <= valleySize - 14'd1;
			writeValleySum <= 1'b0; 
		end
//	else if(writePulseSum && datanum==6'd0)
//		begin
//			pulseAveraging [31] <= pulseSize - 18'd1;
//			writePulseSum <= 1'b0;
//		end
	else if(writePulseSum)
		begin
			pulseAveraging [datanum] <= pulseSize - 18'd1;
			writePulseSum <= 1'b0;
			if(PcountPulse)
				triggerOffset [datanum] <= PpulseSize - 18'd1 + PvalleyAveraging[Pdatanum];
			else
				triggerOffset [datanum] <= PvalleySize - 18'd1;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================	
	if(pulseAveraging[31] > 18'd10)
		dataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		dataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period
	//=======================================================	
	if(dataReady && writePulseSum)
	begin 
		meanPeriod <= sumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
		
	if(dataReady && PdataReady && writePulseSum)
	begin
		meanTriggerOffset <= triggerSum[22:5];
		TdataReady = 1'b1;
	end
	//=======================================================
	//for incrementing array of time values
	//=======================================================
	if((datanum==6'd31 || datanum==6'd32) && countValleyStart)
	begin
		datanum <= 6'd0;
	end
	else if (countValleyStart)
		datanum <= datanum + 6'd1;
		
	//=======================================================
	//for calculating the sum of the last 32 cycles 
	//=======================================================	
	if(countPulseStart && (datanum < 6'd32))// for simplicity, the number of data points is 2^5. This way shift register can be used instead of a divide circuit
	begin
		writeValleySum <= 1'b1;
		if(dataReady)
			sumAveraging <= sumAveraging + valleySize - valleyAveraging [datanum];
		else
			sumAveraging <= sumAveraging + valleySize;
	end
	else if(countValleyStart && (datanum < 6'd32))
	begin
		writePulseSum <= 1'b1;
		if(dataReady && datanum==6'd31)
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[6'd0];
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[6'd0];
			end
		end
		else if (dataReady)
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[datanum + 6'd1];
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[datanum + 6'd1];
			end
		end
		else
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum];
			end
			else
			begin
				triggerSum <= triggerSum  + PvalleySize;
			end
		end
		
		
		if(dataReady && datanum==6'd31)
		begin
			sumAveraging <= sumAveraging + pulseSize - pulseAveraging [6'd0];
		end
		else if(dataReady)
		begin
			sumAveraging <= sumAveraging + pulseSize - pulseAveraging [(datanum + 6'd1)];
		end
		else
		begin
			sumAveraging <= sumAveraging + pulseSize;
		end
	end
end

//***********************PULSER SIGNAL ANALYSIS****************************


//=========================================================
// State conditions for Pulser signal.
//=========================================================

always @(*)
begin
		pulserSignal <= signal1;//GPIO_0[1];
		case(Pstate)
		resetState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountPulseStart=0;
			PcountValleyStart=0;
			if(pulserSignal)
				PnextState = resetState;
			else
				PnextState = beginState;
		end
		beginState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountValleyStart=0;
			if(pulserSignal)
				begin
				PnextState = record1State;
				PcountPulseStart=1;
				end
			else
			begin
				PcountPulseStart=0;
				PnextState = beginState;
			end
		end
		record1State:begin
			PcountValley=0;
			PcountPulse=1;
			PcountPulseStart=0;
			if(pulserSignal==1'b0)
			begin
				PnextState = record2State; 
				PcountValleyStart=1;
			end
			else
			begin
				PnextState = record1State;
				PcountValleyStart=0;
			end
		end
		record2State:begin
			PcountValley=1;
			PcountPulse=0;
			PcountValleyStart=0;
			if(pulserSignal)
			begin
				PnextState = record1State;
				PcountPulseStart=1;
			end
			else
			begin
				PnextState = record2State;
				PcountPulseStart=0;
			end
		end
		default:begin
			PcountValley=0;
			PcountPulse=0;
			PnextState = resetState;
		end
		endcase
end



//=======================================================
//counter for the valley time interval of the Pulser signal(beam OFF)
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	if(PcountValleyStart==1)
		PvalleySize <= 14'd0;
	else if(PcountValley==1)
		PvalleySize <= PvalleySize + 14'd1;
end


//=======================================================
//counter for the pulse time interval of the Pulser signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(PcountPulseStart==1)
		PpulseSize <= 18'd0;
	else if(PcountPulse==1)
		PpulseSize <= PpulseSize + 18'd1;
end

//

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(PwriteValleySum) 
		begin
			PvalleyAveraging [Pdatanum] <= PvalleySize - 14'd1;
			PwriteValleySum <= 1'b0; 
		end
//	else if(writePulseSum && datanum==6'd0)
//		begin
//			pulseAveraging [31] <= pulseSize - 18'd1;
//			writePulseSum <= 1'b0;
//		end
	else if(PwritePulseSum)
		begin
			PpulseAveraging [Pdatanum] <= PpulseSize - 18'd1;
			PwritePulseSum <= 1'b0;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================	
	if(PpulseAveraging[31] > 18'd1)
		PdataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		PdataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period
	//=======================================================	
	if(PdataReady && PwritePulseSum)
	begin
		PmeanPeriod <= PsumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
		
	//=======================================================
	//for incrementing array of time values
	//=======================================================
	if((Pdatanum==6'd31 || Pdatanum==6'd32) && PcountValleyStart)
	begin
		Pdatanum <= 6'd0;
	end
	else if (PcountValleyStart)
		Pdatanum <= Pdatanum + 6'd1;
		
	//=======================================================
	//for calculating the sum of the last 32 cycles 
	//=======================================================	
	if(PcountPulseStart && (Pdatanum < 6'd32))// for simplicity, the number of data points is 2^5. This way shift register can be used instead of a divide circuit
	begin
		PwriteValleySum <= 1'b1;
		if(PdataReady)
			PsumAveraging <= PsumAveraging + PvalleySize - PvalleyAveraging [Pdatanum];
		else
			PsumAveraging <= PsumAveraging + PvalleySize;
	end
	else if(PcountValleyStart && (Pdatanum < 6'd32))
	begin
		PwritePulseSum <= 1'b1;
		if(PdataReady && Pdatanum==6'd31)
		begin
			PsumAveraging <= PsumAveraging + PpulseSize - PpulseAveraging [6'd0];
		end
		else if(PdataReady)
		begin
			PsumAveraging <= PsumAveraging + PpulseSize - PpulseAveraging [(Pdatanum + 6'd1)];
		end
		else
			PsumAveraging <= PsumAveraging + PpulseSize;
	end
end


//***********************Trigger output logic****************************


//=========================================================
// State conditions for Trigger signal.
//=========================================================

always @(*)
begin
	//BeamOn <= GPIO_0[3];
	case(Tstate)
	resetState:begin
		errorReset=0;
		TriggerSignal=1'b0;
		if(resetButton)
			TnextState=resetState;
		else
			TnextState=beginState;
	end
	
	beginState:begin
		TriggerSignal=1'b0;
		if(dataReady && PdataReady)
		begin
			TnextState=KickerOffState;
		end	
		else
			TnextState=beginState;
	end
	
	KickerOnState:begin
		TriggerSignal=1'b1;
		//turnON=0;
		if(error)
			TnextState=errorHighState;
		else if(turnOFF)
		begin
			TnextState=KickerOffState;
		end
		else
			TnextState=KickerOnState;
	end
	
	KickerOffState:begin
		TriggerSignal=1'b0;
	//	turnOFF=0;
		if(error)
			TnextState=errorLowState;
		else if(turnON)//if(BeamOn && turnON)
		begin
				TnextState=KickerOnState;
		end
		else
			TnextState=KickerOffState;
	end
	errorLowState:begin
	TriggerSignal=1'b0;
	if(errorMessageComplete)
	begin
			TnextState = resetState;
			errorReset=1;
	end
	else
	begin
			errorMessageComplete =1;//Still havn't finished this. Should send an error message to the HPS
			TnextState = errorLowState;
			errorReset=0;
	end
	
	end
	errorHighState:begin
	TriggerSignal=1'b1;	
	if(errorClockSize >= 18'd160000)//wait for 2ms. If no ramp down time can be determined in that time, ramp down.
		TnextState = errorLowState;
	else
		TnextState = errorHighState;
	//Should add some logic here to determine the next most likely no-beam period if an error occurs. 
	//some conditions would include: 
	// - the pulse cycle perviously did not make sense, so start a counter based off the clock cycle before that one and ramp accordingly.
	// - the pulse previously did make sense, but now there is no signal. example is maybe the cyclotron turned off? so count based off of the last pulse falling edge.
	// - the 1VM4 signal is messed up, but the pulser signal is fine. This could be an demoulator issue, or adc issue. So just base the ramp down off the pulse signal with a preset offset.	
	end
	default:begin
			TriggerSignal=1'b0;
			TnextState = resetState;
	end
	endcase
end

always@(posedge CLOCK_80MHZ)
begin
	if(Tstate == errorHighState)
		errorClockSize <= errorClockSize + 18'd1;
	else 
		errorClockSize <= 18'd0;
end



always@(posedge CLOCK_80MHZ)
begin
	if(PcountPulse)
	TrigTime <= PvalleyAveraging [Pdatanum] + PpulseSize;
	else if(PcountValley)
	TrigTime <= PvalleySize;
	
	if(resetSwitchCount)
	begin
		switchCount<=7'd1;
		turnOFF <= 1'b0;
		turnON <= 1'b0;
	end
	else if(( TrigTime == meanTriggerOffset) && dataReady && PdataReady && ((Tdatanum == 6'd31 && Pdatanum == 6'd0)||((Tdatanum + 6'd1) == Pdatanum)))
	begin
		if((switchCount == OffRatio) && (Tstate == KickerOffState))
		begin
			switchCount <= 7'd1;
			turnON <= 1'b1;
		end
		else if((switchCount == OnRatio) && (Tstate == KickerOnState))
		begin
			switchCount <= 7'd1;
			turnOFF <= 1'b1;
		end
		else
		begin
			switchCount <= switchCount + 7'd1;
			turnOFF <= 1'b0;
			turnON <= 1'b0;
		end
		if(Tdatanum == 6'd31)
			Tdatanum <= 6'd0;
		else
			Tdatanum <= Tdatanum + 6'd1;
		
	end
	else
	begin
		turnOFF <= 1'b0;
		turnON <= 1'b0;
	end
end

always@(posedge CLOCK_80MHZ)
begin

if(dataReady)
begin
	if (done && countHV<70 && IQvalue>COMPARE)
	begin
		if(countHV<=5)
			countHV <= countHV + 7'b1;
		else
		begin
			highVoltageSum <= highVoltageSum + IQvalue;
			countHV <= countHV + 7'b1;
		end
	end
	else if(IQvalue<COMPARE)
	begin
		countHV <= 7'b0;	
		highVoltageSum <= 19'd0;
	end
	else if(countHV==70)
	begin
		meanHighVoltage <= highVoltageSum [17:6];
	end

	else
	begin
		if (done && countHV<=126 && meanHighVoltage == 12'd0)
		begin
				highVoltageSum <= highVoltageSum + IQvalue;
				countHV <= countHV + 7'b1;
		end
		else if (done && countHV==127  && meanHighVoltage == 12'd0)
				meanHighVoltage <= highVoltageSum [18:7];
	end
end
end
//always@(posedge CLOCK_80MHZ)//cal averaging
//begin
//	if(dataReady)
//	begin
//		
//	end
//end

//always@(posedge countValley)//
//begin
//	pulseAveraging [datanum] <= pulseSize;
//end
//
//always@(posedge countPulse)//
//begin
//	valleyAveraging [datanum] <= valleySize;
//end

assign GPIO_1 = {signal1,3'b000,signal2,3'b000,TriggerSignal,1'b0};
	 //assign LED[0]=(CHAN[0]>COMPARE);Tstate

//assign LED[1]=(CHAN[0]<COMPARE);

//assign LED[2] = SW[0];
//assign LED = KEY[1]? {(CHAN0>COMPARE),(CHAN0<COMPARE),6'd0}:8'hff

//	begin
//			LEDr =	KEY[1]? {CHAN0[11:4]}:8'hff;
//		end
//      else
//		begin
//			LEDr[0]=(CHAN0>COMPARE);
//			LEDr[1]=(CHAN0<COMPARE);
//			LEDr[7:2]=6'd0;
//		end

//======================================================================================
//----------------------------------THINGS TO DO----------------------------------------
//======================================================================================
//Right now it is just averaging the time between triggers for 1vm4 signal. 
//I need to add another reading for the pulser signal and figure out the offset average from 1vm4
//then I need to turn that into the 1:2 ratio and figure out how we are going to edit that. (maybe through gpio and another board)
//then I need to add all the failsafes. valley too small, pulse signal doesn't make sense. etc..
//then I need to figure out how to calculate the pulse on value, and what % of that determines a kick start.

//also I should test the IQ and this program to see the performance




endmodule
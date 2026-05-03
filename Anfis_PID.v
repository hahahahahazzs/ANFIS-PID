module	Anfis_PID(
	input										clk,
	input										rst,
	input							[10:0]	ture_r,													//保留1位小数，在原有的基础上*10	
	input							[10:0]	target_r,												//保留1位小数，在原有的基础上*10
	output	reg	signed	[13:0] 	out	
);


wire	signed	[11:0]	ture;
wire	signed	[11:0]	target;
wire	signed	[11:0]	target1;
reg				[23:0]	cnt0;
wire	signed	[8:0]		error;
reg	signed	[8:0]		e;
reg	signed	[8:0]		e0;
reg	signed	[8:0]		e1;
reg	signed	[8:0]		e2;
wire	signed	[8:0]		ec_r;
reg	signed	[8:0]		ec;
reg	signed	[11:0]	ture0;
reg	signed	[11:0]	ture1;
wire	signed	[8:0]		ha;
		
reg	signed	[18:0]	e_about_l;
reg	signed	[18:0]	e_about_r;
reg	signed	[18:0]	ec_about_l;
reg	signed	[18:0]	ec_about_r;
reg				[2:0]		flag0;
reg				[2:0]		flag1;
reg	signed	[9:0]		a[6:0];
reg	signed	[5:0]		b[6:0];
reg	signed	[11:0]	s0;									//扩大1024
reg	signed	[11:0]	s1;									//扩大1024

reg	signed	[37:0]	w0;
reg	signed	[37:0]	w1;
reg	signed	[37:0]	w2;
reg	signed	[37:0]	w3;
reg	signed	[39:0]	w;

reg	signed	[47:0]	w0_;
reg	signed	[47:0]	w1_;
reg	signed	[47:0]	w2_;
reg	signed	[47:0]	w3_;

reg	signed	[7:0]		kp0;
reg	signed	[7:0]		kp1;
reg	signed	[7:0]		kp2;
reg	signed	[7:0]		kp3;
reg	signed	[7:0]		ki0;
reg	signed	[7:0]		ki1;
reg	signed	[7:0]		ki2;
reg	signed	[7:0]		ki3;
reg	signed	[7:0]		kd0;
reg	signed	[7:0]		kd1;
reg	signed	[7:0]		kd2;
reg	signed	[7:0]		kd3;
reg	signed	[24:0]	y0;
reg	signed	[24:0]	y1;
reg	signed	[24:0]	y2;
reg	signed	[24:0]	y3;
reg	signed	[8:0]		c;

reg	signed	[18:0]	u1_0;
reg	signed	[18:0]	u1_1;
reg	signed	[18:0]	u1_2;
wire	signed	[18:0]	haha;

reg	signed	[1:0]		sgn;

reg	signed	[17:0]	i;	
reg	signed	[17:0]	g;	
reg	signed	[17:0]	h;	
wire	signed	[29:0]	ss;

/***************************数据处理********************/
assign	target1=target_r*10;
assign	target = {1'b0,target1};
assign	ture = {1'b0,ture_r};
/**************************计时器************************/
always@(posedge clk or negedge rst)begin
	if(!rst)
		cnt0 <= 24'd0;
	else begin
		if(cnt0 == 24'd9499999)
			cnt0 <= 24'd0;
		else 
			cnt0 <= cnt0 + 1;		
	end 		
end	
/**************************输入延迟************************/
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		ture0 <= 12'd0;
		ture1 <= 12'd0;
	end else if(cnt0 == 24'd0)begin
		ture0 <= ture;
	   ture1 <= ture0;		
	end
end
	
assign	ha = ture0 - ture1;	
/***************************误差计算**********************/
assign	error = target - ture;
/***************************限幅*************************/
always@(posedge clk or negedge rst)begin
	if(!rst)
		e <= 9'd0;
	else begin
		if(error > 150)
			e <= 9'd150;
		else if(error < -90)
			e <= -9'd90;
		else 
			e <= error;
	end
end	
/**************************输入*************************/
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		e0 <= 9'd0;
      e1 <= 9'd0;
		e2 <= 9'd0;
	end else if(cnt0 == 24'd1)begin
		e0 <= e;
		e1 <= e0;
		e2 <= e1;
	end
end

assign	ec_r = e0 - e1;

always@(posedge clk or negedge rst)begin
	if(!rst)
		ec <= 9'd0;
	else if(cnt0 == 24'd2)begin
		if(ec_r > 15)
			ec <= 9'd15;
		else if(ec_r < -15)
			ec <= -9'd15;
		else 
			ec <= ec_r;
	end
end
/***********************************第一层(求隶属度)(隶属度函数的边界不能更新，否则总体就会改变)******************************/	
initial begin
		a[0] = -10'd90; a[1] = -10'd50; a[2] = -10'd10;a[3] = 10'd30;a[4] = 10'd70;a[5] = 10'd110;a[6] = 10'd150;
		b[0] = -6'd15; b[1] = -6'd10; b[2] = -6'd5; b[3] = 6'd0; b[4] = 6'd5; b[5] = 6'd10; b[6] = 6'd15;	
		s0 = 1024;s1 = 1024;
end	
//=========================================除法=======================================//
wire	signed	[7:0]		de0;
wire	signed	[18:0]	nu0;
wire	signed	[18:0]	qu0;

reg	signed	[7:0]		de0_r;
reg	signed	[18:0]	nu0_r;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		de0_r <= 8'd0; 
	   nu0_r <= 19'd0;
	end else begin
		if(cnt0 == 24'd3)begin
			de0_r <= a[flag0 + 1] - a[flag0];
			nu0_r <= ((a[flag0 + 1] - e)<<<10);
		end else if(cnt0 == 24'd5)begin
			de0_r <= a[flag0 + 1] - a[flag0];
		   nu0_r <= ((e - a[flag0])<<<10);
		end else if(cnt0 == 24'd7)begin
			de0_r <= b[flag1 + 1] - b[flag1];
		   nu0_r <= ((b[flag1 + 1] - ec)<<<10);
		end else if(cnt0 == 24'd9)begin	
			de0_r <= b[flag1 + 1] - b[flag1];
			nu0_r <= ((ec - b[flag1])<<<10);	
		end 
	end
end
	
assign	de0 = de0_r;
assign	nu0 = nu0_r;

lsd my_lsd(
	.denom				(de0),
	.numer				(nu0),
	.quotient			(qu0),
	.remain				()
);
//==========================================e========================================//	
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		flag0 <= 3'd0;
	end else if(cnt0 == 24'd2)begin	
		if(e > a[5] && e <= a[6])begin
			flag0 <= 3'd5;
		end else if(e > a[4] && e <= a[5])begin
			flag0 <= 3'd4;
		end else if(e > a[3] && e <= a[4])begin
			flag0 <= 3'd3;
		end else if(e > a[2] && e <= a[3])begin
			flag0 <= 3'd2;
		end else if(e > a[1] && e <= a[2])begin
			flag0 <= 3'd1;
		end else if(e >= a[0] && e <= a[1])begin
			flag0 <= 3'd0;
		end
	end	
end
	
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		e_about_l <= 19'd0;
		e_about_r <= 19'd0;
	end else if(cnt0 == 24'd5)	
		e_about_l <= qu0;
	else if(cnt0 == 24'd7)
		e_about_r <= qu0;
	else begin
		e_about_l <= e_about_l;
	   e_about_r <= e_about_r;
	end
end
//==========================================ec=================================================//
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		flag1 <= 3'd0;
	end else if(cnt0 == 24'd3)begin	
		if(ec > b[5] && ec <= b[6])begin
			flag1 <= 3'd5;
		end else if(ec > b[4] && ec <= b[5])begin
			flag1 <= 3'd4;
		end else if(ec > b[3] && ec <= b[4])begin
			flag1 <= 3'd3;
		end else if(ec > b[2] && ec <= b[3])begin
			flag1 <= 3'd2;
		end else if(ec > b[1] && ec <= b[2])begin
			flag1 <= 3'd1;
		end else if(ec >= b[0] && ec <= b[1])begin
			flag1 <= 3'd0;
		end
	end	
end		

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		ec_about_l <= 19'd0;
		ec_about_r <= 19'd0;
	end else if(cnt0 == 24'd9)
		ec_about_l <= qu0;
	else if(cnt0 == 24'd11)
		ec_about_r <= qu0;
	else begin
		ec_about_l <= ec_about_l;
		ec_about_r <= ec_about_r;
	end	
end
	
/***********************************第二层(规则)****************************************/
wire	signed	[18:0]	da0;
wire	signed	[18:0]	db0;
wire	signed	[37:0]	re0;

reg	signed	[18:0]	da0_r;
reg	signed	[18:0]	db0_r;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		da0_r <= 18'd0;
		db0_r <= 18'd0;
	end else begin
		if(cnt0 == 24'd12)begin
			da0_r <= e_about_l;
		   db0_r <= ec_about_l;
		end else if(cnt0 == 24'd14)begin	
			da0_r <= e_about_l;
			db0_r <= ec_about_r;
		end else if(cnt0 == 24'd16)begin	
			da0_r <= e_about_r;
			db0_r <= ec_about_l;	
		end else if(cnt0 == 24'd18)begin	
			da0_r <= e_about_r;
			db0_r <= ec_about_r;	
		end
	end
end	
			
assign	da0 = da0_r;
assign	db0 = db0_r;

rule my_rule(
	.dataa			(da0),
	.datab			(db0),
	.result			(re0)
);

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		w0 <= 38'd0;
	   w1 <= 38'd0;
	   w2 <= 38'd0;
	   w3 <= 38'd0;
		w <= 40'd0;
	end else if(cnt0 == 24'd14)
		w0 <= re0;
		else if(cnt0 == 24'd16)
		w1 <= re0;
		else if(cnt0 == 24'd18)
		w2 <= re0;
		else if(cnt0 == 24'd20)
		w3 <= re0;
		else if(cnt0 == 24'd22)
		w <= w0+w1+w2+w3;
end		
/********************************************归一化**********************************************/
wire	signed	[39:0]	de1;
wire	signed	[47:0]	nu1;
wire	signed	[47:0]	qu1;

reg	signed	[39:0]	de1_r;
reg	signed	[47:0]	nu1_r;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		de1_r <= 40'd0; 
	   nu1_r <= 48'd0;
	end else begin
		if(cnt0 == 24'd25)begin
			de1_r <= w;
			nu1_r <= w0 <<< 10;
		end else if(cnt0 == 24'd29)begin
			de1_r <= w;
		   nu1_r <= w1 <<< 10;
		end else if(cnt0 == 24'd33)begin
			de1_r <= w;
		   nu1_r <= w2 <<< 10;
		end else if(cnt0 == 24'd37)begin	
			de1_r <= w;
			nu1_r <= w3 <<< 10;	
		end 
	end
end
	
assign	de1 = de1_r;
assign	nu1 = nu1_r;

norm my_norm(
	.denom				(de1),
	.numer				(nu1),
	.quotient			(qu1),
	.remain				()
);

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		w0_ <= 48'd0;
	   w1_ <= 48'd0;
	   w2_ <= 48'd0;
	   w3_ <= 48'd0;
	end else if(cnt0 == 24'd29)
		w0_ <= qu1;
	else if(cnt0 == 24'd33)
		w1_ <= qu1;
	else if(cnt0 == 24'd37)
		w2_ <= qu1;
	else if(cnt0 == 24'd41)
		w3_ <= qu1;
end
/********************************第四层(解模糊)****************************/
always@(posedge clk or negedge rst)begin
	if(!rst)
		c <= 9'd0;
	else if(cnt0 == 24'd2)
		c <= e0 - e1  - e1 + e2;
end

initial	begin
	kp0 = 1;		ki0 = 14;		kd0 = 1;								//调
   kp1 = 1;		ki1 = 14;		kd1 = 1;								//调
   kp2 = 1;		ki2 = 14;		kd2 = 1;								//调
   kp3 = 1;		ki3 = 14;		kd3 = 1;								//调
end

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		y0 <= 25'd0;
		y1 <= 25'd0;
      y2 <= 25'd0;
      y3 <= 25'd0;
	end else if(cnt0 == 24'd45)begin
		y0 <= ((w0_*(-ec*kp0/30 - e*ki0/20 - c*kd0)));
	   y1 <= ((w1_*(-ec*kp1/30 - e*ki1/20 - c*kd1)));
	   y2 <= ((w2_*(-ec*kp2/30 - e*ki2/20 - c*kd2)));
	   y3 <= ((w3_*(-ec*kp3/30 - e*ki3/20 - c*kd3)));
	end	
end
/*********************************第五层(求和输出)**************************************/
//////////////////////////////////ss赋值/////////////////////////////
assign	ss=((target-ture<30)&&(ture-target<30))?12000:24000;
/////////////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst)begin
	if(!rst)
		u1_0 <= 19'd0;
	else if(cnt0 == 24'd60)
		u1_0 <= (y0 + y1 + y2 + y3)/ss;  			//输入值扩大10倍 此处还原
end		 
 
always@(posedge clk or negedge rst) begin
	if(!rst)
		out <= 14'd0;
	else if(cnt0 == 24'd72) 	
		out <= out + u1_0;
end	

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		u1_1 <= 19'd0;
		u1_2 <= 19'd0;
	end else if(cnt0 == 24'd74)begin	
		u1_1 <= out;
		u1_2 <= u1_1;
	end	
end
		
assign	haha = u1_1 - u1_2;
/********************************训练(梯度下降法)********************************/
//====================================sgn=====================================/
always@(posedge clk or negedge rst)begin
	if(!rst)	
		sgn <= 2'd0;
	else if(cnt0 == 24'd75)begin
		if((ha>0 && haha>0)||(ha<0 && haha<0))
			sgn <= 2'b01;
		else if(haha == 0)begin
			if(ha>0)
				sgn <= 2'b01;
			else if(ha<0)	
				sgn <= 2'b11;
			else 
				sgn <= 2'b00;
		end else if((ha>0 && haha<0)||(ha<0 && haha>0))
			sgn <= 2'b11;
	end
end
//========================================后件参数===================================/	
wire	signed	[8:0]		da1;
wire	signed	[8:0]		db1;
wire	signed	[17:0]	re1;

reg	signed	[8:0]		da1_r;
reg	signed	[8:0]		db1_r;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		da1_r <= 9'd0;
		db1_r <= 9'd0;
	end else begin
		if(cnt0 == 24'd76)begin
			da1_r <= e;
		   db1_r <= ec;	
		end else if(cnt0 == 24'd78)begin
			da1_r <= e;
			db1_r <= e;
		end else if(cnt0 == 24'd80)begin
			da1_r <= e;
			db1_r <= c;	
		end
	end
end	
			
assign	da1 = da1_r;
assign	db1 = db1_r;

lsm my_lsm(
	.dataa				(da1),
	.datab				(db1),
	.result				(re1)
);
	
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		i <= 18'd0;
		g <= 18'd0;
		h <= 18'd0;
	end else begin
		if(cnt0 == 24'd78)begin
			i <= re1*sgn;	
		end else if(cnt0 == 24'd80)begin
			g <= re1*sgn;
		end else if(cnt0 == 24'd82)begin
			h <= re1*sgn;	
		end
	end
end	
	
reg	signed	[64:0]		d_kp0;
reg	signed	[64:0]		d_kp1;
reg	signed	[64:0]		d_kp2;
reg	signed	[64:0]		d_kp3;
reg	signed	[64:0]		d_ki0;
reg	signed	[64:0]		d_ki1;
reg	signed	[64:0]		d_ki2;
reg	signed	[64:0]		d_ki3;
reg	signed	[64:0]		d_kd0;
reg	signed	[64:0]		d_kd1;
reg	signed	[64:0]		d_kd2;
reg	signed	[64:0]		d_kd3;
	
always@(posedge clk or negedge rst)begin                //该部分右移的位数=归一化后的规则激活隶属度右移的10位+PID的P/I/D系数的学习率
	if(!rst)begin
		d_kp0 <= 65'd0;
		d_kp1 <= 65'd0;
		d_kp2 <= 65'd0;
		d_kp3 <= 65'd0;
		d_ki0 <= 65'd0;
		d_ki1 <= 65'd0;
		d_ki2 <= 65'd0;
		d_ki3 <= 65'd0;
		d_kd0 <= 65'd0;
		d_kd1 <= 65'd0;
		d_kd2 <= 65'd0;
		d_kd3 <= 65'd0;
	end else if(cnt0 == 24'd84)begin
		d_kp0 <= (i*w0_)>>>17;											//至少右移17
		d_kp1 <= (i*w1_)>>>17;											//至少右移17
		d_kp2 <= (i*w2_)>>>17;											//至少右移17
		d_kp3 <= (i*w3_)>>>17;											//至少右移17		
	end else if(cnt0 == 24'd88)begin	
		d_ki0 <= (g*w0_)>>>23;											//至少右移17
		d_ki1 <= (g*w1_)>>>23;											//至少右移17
		d_ki2 <= (g*w2_)>>>23;											//至少右移17
		d_ki3 <= (g*w3_)>>>23;											//至少右移17		
	end else if(cnt0 == 24'd92)begin	
		d_kd0 <= (h*w0_)>>>17;											//至少右移17
		d_kd1 <= (h*w1_)>>>17;											//至少右移17
		d_kd2 <= (h*w2_)>>>17;											//至少右移17
		d_kd3 <= (h*w3_)>>>17;											//至少右移17	
	end else if(cnt0 == 24'd96)begin
		if(d_kp0 == -1)
			d_kp0 <= 0;
		else 
			d_kp0 <= d_kp0;
		
		if(d_kp1 == -1)
			d_kp1 <= 0;
		else 
			d_kp1 <= d_kp1;	
				
		if(d_kp2 == -1)
			d_kp2 <= 0;
		else 
			d_kp2 <= d_kp2;
			
		if(d_kp3 == -1)
			d_kp3 <= 0;
		else 
			d_kp3 <= d_kp3;	
		
		if(d_ki0 == -1)
			d_ki0 <= 0;
		else 
			d_ki0 <= d_ki0;
		
		if(d_ki1 == -1)
			d_ki1 <= 0;
		else 
			d_ki1 <= d_ki1;	
				
		if(d_ki2 == -1)
			d_ki2 <= 0;
		else 
			d_ki2 <= d_ki2;
			
		if(d_ki3 == -1)
			d_ki3 <= 0;
		else 
			d_ki3 <= d_ki3;
			
		if(d_kd0 == -1)
			d_kd0 <= 0;
		else 
			d_kd0 <= d_kd0;
		
		if(d_kd1 == -1)
			d_kd1 <= 0;
		else 
			d_kd1 <= d_kd1;	
				
		if(d_kd2 == -1)
			d_kd2 <= 0;
		else 
			d_kd2 <= d_kd2;
			
		if(d_kd3 == -1)
			d_kd3 <= 0;
		else 
			d_kd3 <= d_kd3;													
	end		
end				

always@(posedge clk or negedge rst) begin
	if (!rst) begin
		kp0 <= 1;
		kp1 <= 1;
		kp2 <= 1;
		kp3 <= 1;
		ki0 <= 14;
		ki1 <= 14;
		ki2 <= 14;
		ki3 <= 14;
		kd0 <= 1;
		kd1 <= 1;
		kd2 <= 1;
		kd3 <= 1;
	end else if (cnt0 == 24'd100) begin
		kp0 <= kp0 + d_kp0;
		kp1 <= kp1 + d_kp1;		
		kp2 <= kp2 + d_kp2;	
		kp3 <= kp3 + d_kp3;		
	end else if (cnt0 == 24'd104) begin
		ki0 <= ki0 + d_ki0;	
		ki1 <= ki1 + d_ki1;		
		ki2 <= ki2 + d_ki2;	
		ki3 <= ki3 + d_ki3;
	end else if (cnt0 == 24'd108) begin
		kd0 <= kd0 + d_kd0;	
		kd1 <= kd1 + d_kd1;		
		kd2 <= kd2 + d_kd2;
		kd3 <= kd3 + d_kd3;		
	end
end
	
//===========================================前件参数====================================//
reg	signed	[63:0]	d_s0;					//位宽
reg	signed	[63:0]	d_s1;					//位宽
reg	signed	[63:0]	d_s0r;
reg	signed	[63:0]	d_s1r;
reg	signed	[54:0]	de2_r;
reg	signed	[63:0]	nu2_r;
reg	signed	[54:0]	de3_r;
reg	signed	[63:0]	nu3_r;	

parameter	signed	[3:0]		s0_c = 4;
parameter	signed	[3:0]		s1_c = 5;
parameter	signed	[24:0]	s_xs = 10485760;	 //在实际的基础上扩大10倍

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		de2_r <= 55'd0; 
	   nu2_r <= 64'd0;
		de3_r <= 55'd0; 
	   nu3_r <= 64'd0;
	end else begin
		if(cnt0 == 24'd116)begin
			de2_r <= w*s0*s0*s0_c;
			nu2_r <= (g*(ec_about_l*(y2-y0)+ec_about_r*(y3-y1)))*s_xs;		
		end else if(cnt0 == 24'd136)begin
			de3_r <= w*s1*s1*s1_c;
		   nu3_r <= (i*(e_about_l*(y1-y0)+e_about_r*(y3-y2)))*s_xs;			
		end 
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		d_s0 <= 0;
		d_s1 <= 0;
	end else if (cnt0 == 24'd156) begin
		d_s0 <= nu2_r/de2_r;
		d_s1 <= nu3_r/de3_r;
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		d_s0r <= 0;
		d_s1r <= 0;
	end else if (cnt0 == 24'd176) begin
		d_s0r <= d_s0 >>> 16;					//至少右移4位				调
		d_s1r <= d_s1 >>> 16;					//至少右移4位				调
	end else if (cnt0 == 24'd178) begin
		if(d_s0r == -1)
			d_s0r <= 0;
		else 
			d_s0r <= d_s0r;
		
		if(d_s1r == -1)
			d_s1r <= 0;
		else 
			d_s1r <= d_s1r;
	end	
end
	
always @(posedge clk or negedge rst) begin
	if (!rst) begin
		s0 <= 1024;
		s1 <= 1024;
	end else if (cnt0 == 24'd180) begin
		s0 <= s0 - d_s0r;					//至少右移4位				调
		s1 <= s1 - d_s1r;					//至少右移4位				调
	end
end	
	
always@(negedge clk or negedge rst)begin
	if(!rst)begin
		a[0]	<= -15'd90;
		a[1]	<= -15'd50;
		a[2]	<= -15'd10;
		a[3]	<=  15'd30;
		a[4]	<=  15'd70;
		a[5]	<=  15'd110;
		a[6]	<=  15'd150;
	end else if(cnt0 == 24'd196)begin	
		if(flag0 == 3'd0)begin
			a[0] <= -15'd90;
			a[1] <= (s0 * (flag0 * 40 - 50))>>>10;
		end else if(flag0 == 3'd1)begin
			a[1] <= (s0 * (flag0 * 40 - 90))>>>10;
			a[2] <= (s0 * (flag0 * 40 - 50))>>>10;
		end else if(flag0 == 3'd2)begin
			a[2] <= (s0 * (flag0 * 40 - 90))>>>10;
			a[3] <= (s0 * (flag0 * 40 - 50))>>>10;
		end else if(flag0 == 3'd3)begin
			a[3] <= (s0 * (flag0 * 40 - 90))>>>10;
			a[4] <= (s0 * (flag0 * 40 - 50))>>>10;
		end else if(flag0 == 3'd4)begin
			a[4] <= (s0 * (flag0 * 40 - 90))>>>10;
			a[5] <= (s0 * (flag0 * 40 - 50))>>>10;	
		end else if(flag0 == 3'd5)begin	
			a[5] <= (s0 * (flag0 * 40 - 90))>>>10;
			a[6] <= 15'd150;
		end
	end		
end		
	
always@(negedge clk or negedge rst)begin
	if(!rst)begin
		b[0]	<= -6'd15;
		b[1]	<= -6'd10;
		b[2]	<= -6'd5;
		b[3]	<=  6'd0;	
		b[4]	<=  6'd5;
		b[5]	<=  6'd10;
		b[6]	<=  6'd15;
	end else if(cnt0 == 24'd216)begin	
		if(flag1 == 3'd0)begin
			b[0] <= -6'd15;
			b[1] <= (s1 * 5 * (flag1 - 2))>>>10;
		end else if(flag1 == 3'd1)begin
			b[1] <= (s1 * 5 * (flag1 - 3))>>>10;
			b[2] <= (s1 * 5 * (flag1 - 2))>>>10;
		end else if(flag1 == 3'd2)begin
			b[2] <= (s1 * 5 * (flag1 - 3))>>>10;
			b[3] <= (s1 * 5 * (flag1 - 2))>>>10;
		end else if(flag1 == 3'd3)begin
			b[3] <= (s1 * 5 * (flag1 - 3))>>>10;
			b[4] <= (s1 * 5 * (flag1 - 2))>>>10;
		end else if(flag1 == 3'd4)begin
			b[4] <= (s1 * 5 * (flag1 - 3))>>>10;
			b[5] <= (s1 * 5 * (flag1 - 2))>>>10;
		end else if(flag1 == 3'd5)begin
			b[5] <= (s1 * 5 * (flag1 - 3))>>>10;
			b[6] <= 6'd15;
		end
	end	
end
		
	
endmodule




//"norm"IP核计算结果有问题，有时会多加（0-10），原因未知（可能是现在时间间隔太小）
//更新部分 进行自累加时 当计算出的结果为负值 可能会出现多加1的情况
//out输出会突然变成负最大值




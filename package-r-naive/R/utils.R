findMaxZ<-function(s,t,mincpgs,XS){
	max<-0
	a_max_id<-0
	b_max_id<-1
	S <-function(s,t,XS){
		dat<-as.numeric(XS[,2])
		Sst<-dat[t]
		if (s>1) Sst <- Sst - dat[s=1]
		Sst <- abs(Sst)
		return(Sst)
	}
	if(s<=t){
		for(a in s:t){
			if(a+mincpgs-1<=t){
				for(b in (a+mincpgs-1):t){
					if ((b-a-mincpgs == 0) || ((a ==s) && (b==t)) || (a==b)){
						Zab <- 0
					}else{
						lab <- b - a + 1
						lst <- t - s + 1
						u <- (S(a, b, XS) - (lab * S(s, t, XS)/lst))^2
						Zab <- u / (lab * (1-lab/lst))
					}
					if((is.finite(Zab)==TRUE)&&((a!=s)||(b!=t))&&(max<Zab)) {
						max<-Zab
						a_max_id<-(a-s+1)
						b_max_id<-(b-s+1)
					}
				}
			}
		}
	}
	max_id<-c(a_max_id,b_max_id)
	return(max_id)
}

calcSingleTrendAbs<-function(S,s,t){

	if(s==1){
		trend<-S[t,3]/(t-1)
		trend<-abs(trend)
	}
	else{
		trend<-(S[t,3]-S[s-1,3])/(t-s+1)
		trend<-abs(trend)
	}
	return (trend)
}


noValley<-function(S,s,t,mincpgs,valley){
	if((t-s+1)<mincpgs) {return (1)}
	Sst<-S[t,2]
	minlength<-ifelse(mincpgs>10,mincpgs,10)
	if(s>1){Sst<-Sst-S[s-1,2]}
	mean<-abs(Sst/(t-s+1))

	S0<-as.numeric(S[,2])
	len1<-nrow(S)+1
	S1<-append(S0,rep(0,minlength),0)
	len2<-length(S1)
	S2<-S1[-c(len1:len2)]
	imean<-abs((S0-S2)/minlength)
	imean<-imean[(s+minlength-1):t]
	y<-which(abs(imean)<mean*valley)
	if(length(y)>0){return (0)}
	return (1)
}

cortest<-function(intput_dat,y,cov.mod,a,b){
	x<-as.numeric(colMeans(intput_dat[a:b,-c(1,2)]))
	y <-as.numeric(y[,1])
	if (!is.null(cov.mod)){
		lm.dat <- data.frame(y,x,cov.mod)
	}else{
		lm.dat <- data.frame(y,x)
	}         
	fit <- summary(lm(y~.,data = lm.dat))
	p_value<-fit$coef[2,4]
	coef_lm<-fit$coef[2,1]
	cor_est<-cor(y,x) 
	ret_ks<-c(p_value,coef_lm, cor_est)
	return(ret_ks)
}


calcSingleDiffSum<-function(intput_dat,y){
	calcCR<-function(x){
		x<-as.numeric(x)
		res<-cor(x,y,method = "pearson")
		return(res)
	}
	correlation<-apply(intput_dat[,-c(1,2)],1,calcCR)
	smean<-cumsum(as.numeric(correlation))
	absmean<-abs(smean)
	sigm<-sign(correlation)
	sigsum<-cumsum(sigm)
	S<-cbind(absmean,smean,sigsum)
	return(S)
}



segment_pSTKopt<-function(intput_dat,y,cov.mod,XS,a,b,chr,mincpgs,trend,valley,KS){
	stacks<-NULL
	breaks<-NULL

	child<-0
	ab<-c(-1,0)
	ks1<-c(2,2)
	ks2<-c(2,2)
	ks3<-c(2,2)

	while(length(stacks)||(a!=-1)){
		if((a!=-1)&&(child<=2)){
			if(ab[1]==-1){
				ab<-c(0,0)
				ks1<-c(2,2)
				ks2<-c(2,2)
				ks3<-c(2,2)
				max_id<-findMaxZ(a,b,mincpgs,XS)
				ab<-(a-1)+max_id
				n<-a
				m<-ab[1]-1
				if((ab[1]>1)&&(m-n+1>=mincpgs)&&calcSingleTrendAbs(XS,n,m)>trend&&noValley(XS,n,m,mincpgs,valley)){
					ks1<-cortest(intput_dat,y,cov.mod,n,m)
				}
				n<-ab[1]
				m<-ab[2]
				if(m-n+1>=mincpgs&&calcSingleTrendAbs(XS,n,m)>trend&&noValley(XS,n,m,mincpgs,valley)){
					ks2<-cortest(intput_dat,y,cov.mod,n,m)
				}
				n<-ab[2]+1
				m<-b
				if(m-n+1>=mincpgs&&calcSingleTrendAbs(XS,n,m)>trend&&noValley(XS,n,m,mincpgs,valley)){
					ks3<-cortest(intput_dat,y,cov.mod,n,m)
				}
			}
			newp<-min(ks1[1],ks2[1],ks3[1])
			if((newp<KS[1]||(newp>1&&KS[1]>1))&&(b-a>=mincpgs)){
				stack<-list(a=a,b=b,ab=ab,child=child+1,ks1=ks1,ks2=ks2,ks3=ks3,KS=KS)
				stacks<-append(stacks,list(stack))
				if(child==0){
					n<-a
					m<-ab[1]-1
					a<--1
					if(ab[1]>1&&n<=m){
						if(m-n>=mincpgs){
							a<-n
							b<-m
							KS<-ks1
							child<-0
							ab[1]<--1
						}else{
							bre<-list(chr=chr,start=n,stop=m,p_value=ks1[1],coef_lm=ks1[2],cor_est=ks1[3])
							breaks<-rbind(breaks,data.frame(bre))
						}
					}
				}
				if(child==1){
					n<-ab[1]
					m<-ab[2]
					a<--1
					if(n<=m){
						if(m-n>=mincpgs){
							a<-n
							b<-m
							KS<-ks2
							child<-0
							ab[1]<--1
						}else{
							bre<-list(chr=chr,start=n,stop=m,p_value=ks2[1],coef_lm=ks2[2],cor_est=ks2[3])
							breaks<-rbind(breaks,data.frame(bre))
						}
					}
				}
				if(child==2){
					n<-ab[2]+1
					m<-b
					a<--1
					if(n<=m){
						if(m-n>=mincpgs){
							a<-n
							b<-m
							KS<-ks3
							child<-0
							ab[1]<--1
						}else{
							bre<-list(chr=chr,start=n,stop=m,p_value=ks3[1],coef_lm=ks3[2],cor_est=ks3[3])
							breaks<-rbind(breaks,data.frame(bre))
						}
					}
				}
			}else{
				if(child==0){
					bre<-list(chr=chr,start=a,stop=b,p_value=KS[1],coef_lm=KS[2],cor_est=KS[3])
					breaks<-rbind(breaks,data.frame(bre))
				}
				a<--1
				ab[1]<--1
			}
		}else{
			len<-length(stacks)
			pop<-stacks[[len]]
			stacks[[length(stacks)]]<-NULL
			a<-pop[[1]]
			b<-pop[[2]]
			ab<-pop[[3]]
			child<-pop[[4]]
			ks1<-pop[[5]]
			ks2<-pop[[6]]
			ks3<-pop[[7]]
			KS<-pop[[8]]
			if(child==3){
				a<--1
			}
		}
	}
	return (breaks)
}

segmenterSTK<-function(intput_dat,y,cov.mod,XS,a,b,chr,mincpgs,trend,valley,KS){
	stacks<-NULL
	globalbreaks<-NULL
	while(length(stacks)>0||a!=-1){
		if(a!=-1){
			bre<-segment_pSTKopt(intput_dat,y,cov.mod,XS,a,b,chr,mincpgs,trend,valley,KS)
			i<-which(bre$p_value==min(bre$p_value))
			max<-bre[i,]
			max<-max[1,]
			stack<-list(a=a,b=b,max=max)
			stacks<-append(stacks,list(stack))
			n<-a
			m<-max$start-1
			if(max$start>1&&n<=m){
				ks<-c(2,2)
				if(m-n+1>=mincpgs&&calcSingleTrendAbs(XS,n,m)>trend&&noValley(XS,n,m,mincpgs,valley)){
					ks<-cortest(intput_dat,y,cov.mod,n,m)
				}
				a<-n
				b<-m
				KS<-ks
			}else{
				a<--1
			}
		}
		else{
			pop<-stacks[[length(stacks)]]
			stacks[[length(stacks)]]<-NULL
			a<-pop$a
			b<-pop$b
			max<-pop$max
			globalbreaks<-rbind(globalbreaks,as.data.frame(max))
			n<-max$stop+1
			m<-b
			if(n<=m){
				ks<-c(2,2)
				if(m-n+1>=mincpgs&&calcSingleTrendAbs(XS,n,m)>trend&&noValley(XS,n,m,mincpgs,valley)){
					ks<-cortest(intput_dat,y,cov.mod,n,m)
				}
				a<-n
				b<-m
				KS<-ks
			}else{
				a<--1
			}
		}
	}
	return(globalbreaks)
}

output<-function(intput_dat,y,cov.mod,XS,global,chr,mincpgs,trend,valley){
	tmp<-NULL
	outputList<-NULL
	nbreaks<-nrow(global)
	if(nbreaks>0){
		for(i in 1:nbreaks){
			b<-global[i,]
			if(b$p_value>1){
				if(is.null(tmp)){
					tmp<-b
					methX<-mean(as.numeric(data.matrix(intput_dat[tmp$start:tmp$stop,-c(1,2)])),na.rm=T)
					methY<-mean(as.numeric(data.matrix(y)),na.rm=T)
					tmp$methX<-methX
					tmp$methY<-methY
				}else{
					tmp$stop<-b$stop
				}
			}else{
				if(!is.null(tmp)){
					ks<-c(2,2)
					if(tmp$stop-tmp$start+1>=mincpgs&&calcSingleTrendAbs(XS,tmp$start,tmp$stop)>trend&&noValley(XS,tmp$start,tmp$stop,mincpgs,valley)){
						ks<-cortest(intput_dat,y,cov.mod,tmp$start,tmp$stop)
					}
					if(ks[1]<2){
						out<-data.frame(chr=chr,start=intput_dat$pos[tmp$start]-1,stop=intput_dat$pos[tmp$stop],q=-1,length=tmp$stop-tmp$start+1,cor_est = ks[3],coef_lm=ks[2],p_value=ks[1])
						methX<-mean(as.numeric(data.matrix(intput_dat[tmp$start:tmp$stop,-c(1,2)])),na.rm=T)
						methY<-mean(as.numeric(data.matrix(y)),na.rm=T)
						out$methX<-methX
						out$methY<-methY
						outputList<-rbind(outputList,as.data.frame(out))
					}
					tmp<-NULL
				}
				out<-data.frame(chr=chr,start=intput_dat$pos[b$start]-1,stop=intput_dat$pos[b$stop],q=-1,length=b$stop-b$start+1,cor_est =b$cor_est,coef_lm=b$coef_lm,p_value=b$p_value)
				methX<-mean(as.numeric(data.matrix(intput_dat[b$start:b$stop,-c(1,2)])),na.rm=T)
				methY<-mean(as.numeric(data.matrix(y)),na.rm=T)
				out$methX<-methX
				out$methY<-methY
				outputList<-rbind(outputList,as.data.frame(out))
			}
		}
	}
	if(!is.null(tmp)){
		ks<-c(2,2)
		if(tmp$stop-tmp$start+1>=mincpgs&&calcSingleTrendAbs(XS,tmp$start,tmp$stop)>trend&&noValley(XS,tmp$start,tmp$stop,mincpgs,valley)){
			ks<-cortest(intput_dat,y,cov.mod,tmp$start,tmp$stop)
		}
		if(ks[1]<2){
			out<-data.frame(chr=chr,start=intput_dat$pos[tmp$start]-1,stop=intput_dat$pos[tmp$stop],q=-1,length=tmp$stop-tmp$start+1,cor_est = ks[3],coef_lm=ks[2],p_value=ks[1])
			methX<-mean(as.numeric(data.matrix(intput_dat[tmp$start:tmp$stop,-c(1,2)])),na.rm=T)
			methY<-mean(as.numeric(data.matrix(y)),na.rm=T)
			out$methX<-methX
			out$methY<-methY
			outputList<-rbind(outputList,as.data.frame(out))
		}
		tmp<-NULL
	}
	return(outputList)
}

segmentation<-function(intput_dat,y,cov.mod,chr,mincpgs,trend,valley){
	ks<-c(2,2)
	len<-nrow(intput_dat)
	XS<-calcSingleDiffSum(intput_dat,y)
	if(len-1>=mincpgs&&calcSingleTrendAbs(XS,1,len)>trend&&noValley(XS,1,len,mincpgs,valley)){
		ks<-cortest(intput_dat,y,cov.mod,1,len)
	}
	globalbreaks<-segmenterSTK(intput_dat,y,cov.mod,XS,1,len,chr,mincpgs,trend,valley,ks)
	outputList<-output(intput_dat,y,cov.mod,XS,globalbreaks,chr,mincpgs,trend,valley)
	return (outputList)
}


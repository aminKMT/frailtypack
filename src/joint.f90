	

!AD:sortie fortran
	module sortie
	integer,save::cptaux,cptcens,nb0recu
	double precision::moyrecu
	end module sortie
!AD:



	module donnees
	
	implicit none
	double precision,dimension(6)::cof
	double precision::stp,half,one,fpf
	double precision,dimension(20),save::x,w!The abscissas-weights.
	double precision,dimension(32),save::x1,w1!The abscissas-weights.
	
	DATA w/0.181080062419,0.422556767879,0.666909546702,0.91535237279, &
	1.1695397071,1.43135498624,1.7029811359,1.98701589585, &
	2.28663576323,2.60583465152,2.94978381794,3.32539569477, &
	3.74225636246,4.21424053477,4.76252016007,5.42172779036, &
	6.25401146407,7.38731523837,9.15132879607,12.8933886244/
	
	DATA x/0.070539889692,0.372126818002,0.916582102483,1.70730653103, &
	2.74919925531,4.04892531384,5.61517497087,7.45901745389, &
	9.59439286749,12.0388025566,14.8142934155,17.9488955686, &
	21.4787881904,25.4517028094,29.9325546634,35.0134341868, &
	40.8330570974,47.6199940299,55.8107957541,66.5244165252/
	
	data cof,stp/76.18009173d0,-86.50532033d0,24.01409822d0, &
	-1.231739516d0,.120858003d-2,-.536382d-5,2.50662827465d0/
	data half,one,fpf/0.5d0,1.0d0,5.5d0/
	
	DATA w1/0.114187105768,0.266065216898,0.418793137325,0.572532846497 &
	,0.727648788453,0.884536718946,1.04361887597,1.20534920595, &
	1.37022171969,1.53877595906,1.71164594592,1.8895649683, &
	2.07318851235,2.26590144444,2.46997418988,2.64296709494, &
	2.76464437462,3.22890542981,2.92019361963,4.3928479809, &
	4.27908673189,5.20480398519,5.11436212961,4.15561492173, &
	6.19851060567,5.34795780128,6.28339212457,6.89198340969, &
	7.92091094244,9.20440555803,11.1637432904,15.3902417688/
	
	DATA x1/0.0444893658333,0.23452610952,0.576884629302,1.07244875382, &
	1.72240877644,2.52833670643,3.49221327285,4.61645677223, &
	5.90395848335,7.3581268086,8.98294126732,10.783012089, &
	12.763745476,14.9309117981,17.2932661372,19.8536236493, &
	22.6357789624,25.6201482024,28.8739336869,32.3333294017, &
	36.1132042245,40.1337377056,44.5224085362,49.2086605665, &
	54.3501813324,59.8791192845,65.9833617041,72.6842683222, &
	80.1883747906,88.735192639,98.8295523184,111.751398227/	
	
	end module donnees
!=======================================================================================
!=======================================================================================
!                                FIN marq98 version optim
!=======================================================================================
!=======================================================================================


	module splines
	
	double precision,dimension(:),allocatable,save::aux
	double precision,dimension(:),allocatable,save:: v
	double precision,dimension(:,:),allocatable,save::I1_hess,H1_hess
	double precision,dimension(:,:),allocatable,save::I2_hess,H2_hess
	double precision,dimension(:,:),allocatable,save::HI2
	double precision,dimension(:,:),allocatable,save::HIH,IH,HI
	double precision,dimension(:,:),allocatable,save::BIAIS
	double precision,dimension(:),allocatable,save:: vax,vaxdc
	integer,dimension(:),allocatable,save::filtre,filtre2
	character(LEN=20),dimension(:),allocatable,save:: nomvar,nomvar2
	integer,save::ver
	
	end module splines





!--entête pour fortran	
	subroutine joint(nsujet0,ng0,nz0,k0,tt00,tt10,ic0,groupe0      &
	,tt0dc0,tt1dc0,icdc0,nva10,vax0,nva20,vaxdc0,noVar1,noVar2,maxit0   &
	,np,b,H_hessOut,HIHOut,resOut,LCV,x1Out,lamOut,xSu1,suOut,x2Out,lam2Out,xSu2,su2Out &
	,typeof0,equidistant,nbintervR0,nbintervDC0,mt1,mt2 &
	,ni,cpt,cpt_dc,ier,istop,shape_weib,scale_weib,mt11,mt12)
!AD: add for new marq    
	use parameters	
!AD:end
	use comon
	use tailles
	use splines
	use optim
!AD:pour fortran	
	use sortie
!AD:
	IMPLICIT NONE  
	
	integer::maxit0,mt11,mt12
	integer,intent(in)::nsujet0,ng0,nz0,nva10,nva20,mt1,mt2
	integer::np,equidistant
	integer,dimension(nsujet0)::groupe0,ic0
	integer,dimension(ng0),intent(in)::icdc0
	double precision,dimension(ng0)::tt0dc0,tt1dc0
	double precision,dimension(nsujet0)::tt00,tt10
	double precision,dimension(2)::k0
	double precision,dimension(nsujet0,nva10),intent(in):: vax0
	double precision,dimension(ng0,nva20),intent(in):: vaxdc0
	double precision,dimension(np,np)::H_hessOut,HIHOut
	double precision::resOut
	double precision,dimension(mt1)::x1Out
	double precision,dimension(mt2)::x2Out
	double precision,dimension(mt1,3)::lamOut
	double precision,dimension(mt11,3)::suOut
	double precision,dimension(mt2,3)::lam2Out
	double precision,dimension(mt12,3)::su2Out
	integer::ss,sss
	double precision,dimension(np):: b
	double precision,dimension(2),intent(out)::LCV,shape_weib,scale_weib
	
	integer,intent(in)::noVar1,noVar2
	integer,intent(out)::cpt,cpt_dc,ier,ni
	integer::groupe,ij,kk,j,k,nz,n,ii,iii,iii2,cptstr1,cptstr2   &
	,i,ic,icdc,istop,cptni,cptni1,cptni2,nb_echec,nb_echecor,id,cptbiais &
	,cptauxdc   
	double precision::tt0,tt0dc,tt1,tt1dc,h,res,min,mindc,max, &
	maxdc,maxt,maxtdc,moy_peh0,moy_peh1,lrs,BIAIS_moy
	double precision,dimension(2)::res01
!AD: add for new marq
	double precision::ca,cb,dd
	double precision,external::funcpaj_splines,funcpaj_cpm,funcpaj_weib
	double precision,dimension(100)::xSu1,xSu2
!cpm
	integer::indd,ent,entdc,typeof0
	double precision::temp	
	integer::nbintervR0,nbintervDC0	

	typeof = typeof0
	model = 1
	
	indic_alpha = 1

	if (typeof .ne. 0) then
		nbintervR = nbintervR0
		nbintervDC = nbintervDC0
	end if
	
	
	maxiter = maxit0
!AD:add for new marq
	epsa = 1.d-3
	epsb = 1.d-3
	epsd = 1.d-3
!AD:end 
				
	lrs = 0.d0
	moy_peh0 = 0.d0
	moy_peh1 = 0.d0
	
	nb_echec = 0
	nb_echecor = 0
	nb0recu = 0
	moyrecu =0.d0             
		
	ngmax=ng0
	ng=ng0
	allocate(nig(ngmax),cdc(ngmax),t0dc(ngmax),t1dc(ngmax),aux1(ngmax),aux2(ngmax) &
	,res1(ngmax),res4(ngmax),res3(ngmax),mi(ngmax))
	
	shape_weib = 0.d0
	scale_weib = 0.d0	
	nsujetmax=nsujet0
	nsujet=nsujet0	    
	allocate(t0(nsujetmax),t1(nsujetmax),c(nsujetmax),stra(nsujetmax),g(nsujetmax),aux(2*nsujetmax))


	ndatemaxdc=2*ng0     

	if (typeof == 0) then
		allocate(nt0dc(ngmax),nt1dc(ngmax),nt0(nsujetmax),nt1(nsujetmax))
		allocate(mm3dc(ndatemaxdc),mm2dc(ndatemaxdc),mm1dc(ndatemaxdc),mmdc(ndatemaxdc) &
		,im3dc(ndatemaxdc),im2dc(ndatemaxdc),im1dc(ndatemaxdc),imdc(ndatemaxdc))
	end if	

	nst=2	
	ni=0      
!---debut des iterations de simulations       
	id=1
	cptni=0
	cptni1=0
	cptni2=0
	biais_moy=0.d0
	cptbiais=0
	cptaux=0
	cptauxdc=0
	ij=0
	kk=0
	groupe=0
	n=0
	nz=0
!**************************************************
!********************* prog spline****************
	effet=1
	res01(1)=0.d0
	res01(2)=0.d0
!------------  entre non fichier et nombre sujet -----        
	nvarmax=ver
	
	allocate(vax(nva10),vaxdc(nva20))
			
	nva1=nva10
	nva2=nva20
	nva = nva1+nva2
	nvarmax=nva
	
	allocate(ve(nsujetmax,nvarmax),vedc(ngmax,nvarmax))
	allocate(filtre(nva10),filtre2(nva20))
	
	nig=0
	   
! AD: recurrent
	if (noVar1.eq.1) then 
!		write(*,*)'filtre 1 desactive'
		filtre=0
		nva1=0
	else
		filtre=1
	end if	
!AD:death
	if (noVar2.eq.1) then 
!		write(*,*)'filtre 2 desactive'
		filtre2=0
		nva2=0
	else
		filtre2=1
	end if	
	
	if ((noVar1.eq.1).or.(noVar2.eq.1)) then
		nva = nva1+nva2 
	end if
	
		
!AD:end
                  
!------------  lecture fichier -----------------------
	maxt = 0.d0
	maxtdc = 0.d0
	cpt = 0
	cptcens = 0
	cpt_dc = 0
	k = 0
	cptstr1 = 0
	cptstr2 = 0
   
!ccccccccccccccccccccc
! pour le deces
!cccccccccccccccccccc

	do k = 1,ng 
		tt0dc=tt0dc0(k)
		tt1dc=tt1dc0(k)
		icdc=icdc0(k)
		groupe=groupe0(k)
		do j=1,nva20	    
			vaxdc(j)=vaxdc0(k,j)
		enddo	    	    
		if(tt0dc.gt.0.d0)then
			cptauxdc=cptauxdc+1
		endif                  
!------------------   deces c=1 pour donn�es de survie
		if(icdc.eq.1)then
			cpt_dc = cpt_dc + 1
			cdc(k)=1
			t0dc(k) = tt0dc      !/100.d0
			t1dc(k) = tt1dc      !+0.000000001
			iii = 0
			iii2 = 0	       
			do ii = 1,nva20
				if(filtre2(ii).eq.1)then
					iii2 = iii2 + 1
					vedc(k,iii2) = dble(vaxdc(ii))
				endif
			end do   
		else 
!------------------   censure a droite ou event recurr  c=0 
			if(icdc.eq.0)then
				cdc(k) = 0 
				iii = 0
				iii2 = 0
				do ii = 1,nva20
					if(filtre2(ii).eq.1)then
					iii2 = iii2 + 1
					vedc(k,iii2) = dble(vaxdc(ii))
					endif
				end do 
				t0dc(k) =  tt0dc 
				t1dc(k) = tt1dc    
			endif
		endif
		if (maxtdc.lt.t1dc(k))then
			maxtdc = t1dc(k)
		endif
	end do

!AD:
	if (typeof .ne. 0) then 
		cens = maxtdc
	end if
!Ad	
	k = 0
	cptstr1 = 0
	cptstr2 = 0

!cccccccccccccccccccccccccccccccccc
! pour les donn�es recurrentes  
!cccccccccccccccccccccccccccccccccc     	 
	do i = 1,nsujet     !sur les observations
		tt0=tt00(i)
		tt1=tt10(i)
		ic=ic0(i)
		groupe=groupe0(i)	       	       	    
!-------------------	    
		do j=1,nva10	    
			vax(j)=vax0(i,j)
		enddo
!--------------	    	    
		if(tt0.gt.0.d0)then
			cptaux=cptaux+1
		endif  	                      
!-----------------------------------------------------
            
!     essai sans troncature
!     tt0=0.
!------------------   observation c=1 pour donn�es recurrentes
		if(ic.eq.1)then
			cpt = cpt + 1
			c(i)=1
			t0(i) = tt0 
			t1(i) = tt1  
			t1(i) = t1(i)
			g(i) = groupe
			nig(groupe) = nig(groupe)+1 ! nb d event recurr dans un groupe
			iii = 0
			iii2 = 0
!                  do ii = 1,ver		  
			do ii = 1,nva10
				if(filtre(ii).eq.1)then
					iii = iii + 1
					ve(i,iii) = dble(vax(ii)) !ici sur les observations
				endif
			end do   
		else 
!------------------   censure a droite  c=0 pour donn�es recurrentes
			if(ic.eq.0)then
				cptcens=cptcens+1
				c(i) = 0 
				iii = 0
				iii2 = 0
		!                     do ii = 1,ver
				do ii = 1,nva10
					if(filtre(ii).eq.1)then
					iii = iii + 1
					ve(i,iii) = dble(vax(ii))
					endif
				end do 
				t0(i) =  tt0 
				t1(i) = tt1 
				t1(i) = t1(i) 
				g(i) = groupe
			endif
		endif
		if (maxt.lt.t1(i))then
			maxt = t1(i)
		endif
	end do 
         	
	nsujet=i-1

	if (typeof == 0) then	
		nz=nz0
		nz1=nz
		nz2=nz
		
		if(nz.gt.20)then
			nz = 20
		endif
		if(nz.lt.4)then
			nz = 4
		endif
	end if
	 
	ndatemax=2*nsujet
	allocate(date(ndatemax),datedc(ndatemax))
	
	if(typeof == 0) then
		allocate(mm3(ndatemax),mm2(ndatemax) &
		,mm1(ndatemax),mm(ndatemax),im3(ndatemax),im2(ndatemax),im1(ndatemax),im(ndatemax))
	end if
        
!!!  DONNEES DECES

	mindc = 0.d0
	maxdc = maxtdc
	do i = 1,2*ng	 
		do k = 1,ng
			if((t0dc(k).ge.mindc))then
				if(t0dc(k).lt.maxdc)then
					maxdc = t0dc(k)
				endif
			endif
			if((t1dc(k).ge.mindc))then
				if(t1dc(k).lt.maxdc)then
					maxdc = t1dc(k)
				endif
			endif
		end do   
		aux(i) = maxdc
		mindc = maxdc + 1.d-12
		maxdc = maxtdc
	end do

	datedc(1) = aux(1)
	k = 1
	do i=2,2*ng
		if(aux(i).gt.aux(i-1))then
			k = k+1
			datedc(k) = aux(i)
		endif 
	end do 
	
	if(typeof == 0) then
		ndatedc = k   
	end if   
!!         write(*,*)'** ndatemax,ndatemaxdc',ndatemax,ndatemaxdc	        
!--------------- zi- ----------------------------------

!      construire vecteur zi (des noeuds)

!!! DONNEES RECURRENTES

	min = 0.d0
	aux =0.d0
	max = maxt

	do i = 1,2*nsujet
		do k = 1,nsujet
			if((t0(k).ge.min))then
				if(t0(k).lt.max)then
					max = t0(k)
				endif
			endif
			if((t1(k).ge.min))then
				if(t1(k).lt.max)then
					max = t1(k)
				endif
			endif
		end do   
		aux(i) = max
		min = max + 1.d-12
		max = maxt
	end do

	date(1) = aux(1)
	k = 1
	do i=2,2*nsujet
		if(aux(i).gt.aux(i-1))then
			k = k+1
			date(k) = aux(i)
		endif 
	end do 
	
	if(typeof == 0) then
		ndate = k
		nzmax=nz+3
			
		allocate(zi(-2:nzmax))
		zi(-2) =0
		zi(-2) = date(1) 
		zi(-1) = date(1)
		zi(0) = date(1)
		zi(1) = date(1)

		h = (date(ndate)-date(1))/dble(nz-1)
	
		do i=2,nz-1
			zi(i) =zi(i-1) + h
		end do

		zi(nz) = date(ndate)
		zi(nz+1)=zi(nz)
		zi(nz+2)=zi(nz)
		zi(nz+3)=zi(nz)

	end if
!---------- affectation nt0dc,nt1dc DECES ----------------------------
	indictronqdc=0
	do k=1,ng 
		if (typeof == 0) then
			if(nig(k).eq.0.d0)then
				nb0recu = nb0recu + 1 !donne nb sujet sans event recu
			endif
			moyrecu =  moyrecu + dble(nig(k))
		
			if(t0dc(k).eq.0.d0)then
				nt0dc(k) = 0
			endif
		end if

		if(t0dc(k).ne.0.d0)then
			indictronqdc=1
		endif

		if (typeof == 0) then
			do j=1,ndatedc
				if(datedc(j).eq.t0dc(k))then
					nt0dc(k)=j
				endif
				if(datedc(j).eq.t1dc(k))then
					nt1dc(k)=j
				endif
			end do
		end if
	end do 

!---------- affectation nt0,nt1 RECURRENTS----------------------------

	indictronq=0
	do i=1,nsujet 
		if (typeof == 0) then
			if(t0(i).eq.0.d0)then
				nt0(i) = 0
			endif
		end if

		if(t0(i).ne.0.d0)then
			indictronq=1
		endif
		if (typeof == 0) then
			do j=1,ndate
				if(date(j).eq.t0(i))then
				nt0(i)=j
				endif
				if(date(j).eq.t1(i))then
				nt1(i)=j
				endif
			end do
		end if
	end do 

	if (typeof == 0) then
!---------- affectation des vecteurs de splines -----------------        
		n  = nz+2
!AD:add argument:ndatedc
		call vecspliJ(n,ndate,ndatedc) 
!AD:end	
		allocate(m3m3(nzmax),m2m2(nzmax),m1m1(nzmax),mmm(nzmax),m3m2(nzmax) &
		,m3m1(nzmax),m3m(nzmax),m2m1(nzmax),m2m(nzmax),m1m(nzmax)) 
			
		call vecpenJ(n)
	end if
	
	npmax=np
	
	allocate(I_hess(npmax,npmax),H_hess(npmax,npmax),Hspl_hess(npmax,npmax) &
	,PEN_deri(npmax,1),hess(npmax,npmax),v((npmax*(npmax+3)/2)),I1_hess(npmax,npmax) &
	,H1_hess(npmax,npmax),I2_hess(npmax,npmax),H2_hess(npmax,npmax),HI2(npmax,npmax) & 
	,HIH(npmax,npmax),IH(npmax,npmax),HI(npmax,npmax),BIAIS(npmax,1))

	if (typeof .ne. 0) then
		allocate(vvv((npmax*(npmax+1)/2)))	
	end if
     
!------- initialisation des parametres
                   
	do i=1,npmax
		b(i)=5.d-1
	end do
	
	if(typeof ==1) then
		b(1:nbintervR) = 0.8d0!1.d-2!
		b((nbintervR+1):(nbintervR+nbintervDC)) = 0.8d0!1.d-2
		b(np-nva-indic_alpha)=5.d-1 ! pour theta
	end if

!	write(*,*)'typeof',typeof
	
	if (typeof == 2) then
!		b(1:4)=1.d-1!0.8d0	
	!	b(np-nva-indic_alpha)=5.d-1 ! pour theta
	!	b(np-nva-indic_alpha)=1.d0 ! pour theta	
	end if

	if (typeof == 0) then
		b(np-nva-indic_alpha)=1.d0 ! pour theta	
	end if
	
	b(np-nva)=1.d0



	if (typeof == 1) then
!------- RECHERCHE DES NOEUDS
!----------> Enlever les zeros dans le vecteur de temps
		i=0
		j=0
!----------> taille - nb de recu
		do i=1,nsujet
			if(t1(i).ne.(0.d0).and.c(i).eq.1) then
				j=j+1
			endif
		end do
		nbrecu=j
!----------> allocation des vecteur temps
		allocate(t2(nbrecu))
		
!----------> remplissage du vecteur de temps
		j=0
		do i=1,nsujet
			if (t1(i).ne.(0.d0).and.c(i).eq.1) then
				j=j+1
				t2(j)=t1(i)
			endif
		end do
		
!----------> tri du vecteur de temps
		indd=1
		do while (indd.eq.1)
			indd=0
			do i=1,nbrecu-1
				if (t2(i).gt.t2(i+1)) then
					temp=t2(i)
					t2(i)=t2(i+1)
					t2(i+1)=temp
					indd=1        
				end if
			end do
		end do	
		
		ent=int(nbrecu/nbintervR)
		
		allocate(ttt(0:nbintervR))
		
		ttt(0)=0.d0
		ttt(nbintervR)=cens
		
		j=0
		do j=1,nbintervR-1
			if (equidistant.eq.0) then
				ttt(j)=(t2(ent*j)+t2(ent*j+1))/(2.d0)
			else
				ttt(j)=(cens/nbintervR)*j
			endif
		end do
		
!----------> taille - nb de deces
		j=0
		do i=1,ngmax
			if(t1dc(i).ne.(0.d0).and.cdc(i).eq.1)then
				j=j+1
			endif
		end do
		nbdeces=j
		
!----------> allocation des vecteur temps
		allocate(t3(nbdeces))	 
!----------> remplissage du vecteur de temps
		j=0
		do i=1,ngmax
			if(t1dc(i).ne.(0.d0).and.cdc(i).eq.1)then
				j=j+1
				t3(j)=t1dc(i)
			endif
		end do	 	 
!----------> tri du vecteur de temps
		indd=1
		do while (indd.eq.1)
			indd=0
			do i=1,nbdeces-1
				if (t3(i).gt.t3(i+1)) then
					temp=t3(i)
					t3(i)=t3(i+1)
					t3(i+1)=temp
					indd=1        
				end if
			end do
		end do 	 
	 
		entdc=int(nbdeces/nbintervDC)
		allocate(tttdc(0:nbintervDC))
		tttdc(0)=0.d0
		tttdc(nbintervDC)=cens
		
		j=0 
		do j=1,nbintervDC-1
			if (equidistant.eq.0) then	
				tttdc(j)=(t3(entdc*j)+t3(entdc*j+1))/(2.d0)
			else
				tttdc(j)=(cens/nbintervDC)*j
			endif
		end do	 

		deallocate(t2,t3)
!------- FIN RECHERCHE DES NOEUDS	
	end if		

	ca=0.d0
	cb=0.d0
	dd=0.d0	
	if (typeof .ne. 0) then
		allocate(kkapa(2))
	end if	
	
	select case(typeof)
		case(0)
			call marq98J(k0,b,np,ni,v,res,ier,istop,effet,ca,cb,dd,funcpaj_splines)
		case(1)
			allocate(betacoef(nbintervR+nbintervDC))
			call marq98J(k0,b,np,ni,v,res,ier,istop,effet,ca,cb,dd,funcpaj_cpm)
		case(2)
			call marq98J(k0,b,np,ni,v,res,ier,istop,effet,ca,cb,dd,funcpaj_weib)
	end select
	
	if (typeof .ne. 0) then
		deallocate(kkapa)
	end if	
	
	resOut=res
	
	if (istop .ne. 1) then
		goto 1000
	end if
	
	
	
	call multiJ(I_hess,H_hess,np,np,np,IH)
	call multiJ(H_hess,IH,np,np,np,HIH)   
		
	if(effet.eq.1.and.ier.eq.-1)then
	v((np-nva-indic_alpha)*(np-nva-indic_alpha+1)/2)=10.d10

	endif          
	res01(effet+1)=res
	 
! --------------  Lambda and survival estimates JRG January 05

	select case(typeof)
		case(0)
			call distanceJ_splines(nz1,nz2,b,mt1,mt2,x1Out,lamOut,suOut,x2Out,lam2Out,su2Out)
		case(1)
			Call distanceJ_cpm(b,nbintervR+nbintervDC,mt1,mt2,x1Out,lamOut,xSu1,suOut,x2Out,lam2Out,xSu2,su2Out)
		case(2)
			Call distanceJ_weib(b,np,mt1,x1Out,lamOut,xSu1,suOut,x2Out,lam2Out,xSu2,su2Out)
	end select
	
	if (nst == 1) then
		scale_weib(1) = betaR
		shape_weib(1) = etaR
		scale_weib(2) = 0.d0
		shape_weib(2) = 0.d0
	else
		scale_weib(1) = betaR
		shape_weib(1) = etaR
		scale_weib(2) = betaD
		shape_weib(2) = etaD
	end if
		
	do ss=1,npmax
		do sss=1,npmax
			HIHOut(ss,sss) = HIH(ss,sss)
			H_hessOut(ss,sss)= H_hess(ss,sss)
		end do  
	end do

!AD:add LCV
!LCV(1) The approximate like cross-validation Criterion
!LCV(2) Akaike information Criterion 
!     calcul de la trace, pour le LCV (likelihood cross validation)
	LCV=0.d0
	if (typeof == 0) then	
!		write(*,*)'The approximate like cross-validation Criterion in the non parametric case'		
		call multiJ(H_hess,I_hess,np,np,np,HI)	
		do i =1,np
			LCV(1) = LCV(1) + HI(i,i)
		end do 	
		LCV(1) = (LCV(1) - resnonpen) / nsujet
	else		
!		write(*,*)'=========> Akaike information Criterion <========='
		LCV(2) = (1.d0 / nsujet) *(np - resOut)
!		write(*,*)'======== AIC :',LCV(2)	
	end if
	

1000 continue	
!AD:end
	deallocate(nig,cdc,t0dc,t1dc,aux1,aux2,res1,res4,res3,mi,t0,t1,c,stra,g, &
	aux,vax,vaxdc,ve,vedc,filtre,filtre2,I_hess,H_hess,Hspl_hess,PEN_deri, &
	hess,v,I1_hess,H1_hess,I2_hess,H2_hess,HI2,HIH,IH,HI,BIAIS,date,datedc)
		
	if (typeof == 0) then
		deallocate(nt0dc,nt1dc,nt0,nt1,mm3dc,mm2dc,mm1dc,mmdc,im3dc,im2dc,im1dc,imdc, &
		mm3,mm2,mm1,mm,im3,im2,im1,im,zi,m3m3,m2m2,m1m1,mmm,&
		m3m2,m3m1,m3m,m2m1,m2m,m1m)
	end if
	
	if (typeof .ne. 0) then
		deallocate(vvv)	
	end if	
	
	if (typeof == 1) then	
		deallocate(ttt,tttdc,betacoef)
	end if
	
	return
	
	end subroutine joint
      

!========================== VECSPLI ==============================
!AD:add argument:ndatedc 
	subroutine vecspliJ(n,ndate,ndatedc) 
!AD:end	
	use tailles
!AD:	
	use comon,only:date,datedc,zi,mm3,mm2,mm1,mm,im3,im2,im1,im &
	,mm3dc,mm2dc,mm1dc,mmdc,im3dc,im2dc,im1dc,imdc
!AD:end	
	IMPLICIT NONE
	
	integer,intent(in)::n,ndate,ndatedc
	integer::i,j,k
	double precision::ht,htm,h2t,ht2,ht3,hht,h,hh,h2,h3,h4,h3m,h2n,hn,hh3,hh2
      
!----------  calcul de u(ti) :  STRATE1 ---------------------------
!    attention the(1)  sont en nz=1
!        donc en ti on a the(i)
	j=0
	do i=1,ndate-1
		do k = 2,n-2
			if ((date(i).ge.zi(k-1)).and.(date(i).lt.zi(k)))then
				j = k-1
			endif
		end do 
		ht = date(i)-zi(j)
		htm= date(i)-zi(j-1)
		h2t= date(i)-zi(j+2)
		ht2 = zi(j+1)-date(i)
		ht3 = zi(j+3)-date(i)
		hht = date(i)-zi(j-2)
		h = zi(j+1)-zi(j)
		hh= zi(j+1)-zi(j-1)
		h2= zi(j+2)-zi(j)
		h3= zi(j+3)-zi(j)
		h4= zi(j+4)-zi(j)
		h3m= zi(j+3)-zi(j-1)
		h2n=zi(j+2)-zi(j-1)
		hn= zi(j+1)-zi(j-2)
		hh3 = zi(j+1)-zi(j-3)
		hh2 = zi(j+2)-zi(j-2)
		mm3(i) = ((4.d0*ht2*ht2*ht2)/(h*hh*hn*hh3))
		mm2(i) = ((4.d0*hht*ht2*ht2)/(hh2*hh*h*hn))+((-4.d0*h2t*htm &
		*ht2)/(hh2*h2n*hh*h))+((4.d0*h2t*h2t*ht)/(hh2*h2*h*h2n))
		mm1(i) = (4.d0*(htm*htm*ht2)/(h3m*h2n*hh*h))+((-4.d0*htm*ht* &
		h2t)/(h3m*h2*h*h2n))+((4.d0*ht3*ht*ht)/(h3m*h3*h2*h))
		mm(i)  = 4.d0*(ht*ht*ht)/(h4*h3*h2*h)
		im3(i) = (0.25d0*(date(i)-zi(j-3))*mm3(i))+(0.25d0*hh2 &
		*mm2(i))+(0.25d0*h3m*mm1(i))+(0.25d0*h4*mm(i))
		im2(i) = (0.25d0*hht*mm2(i))+(h3m*mm1(i)*0.25d0) &
			+(h4*mm(i)*0.25d0)
		im1(i) = (htm*mm1(i)*0.25d0)+(h4*mm(i)*0.25d0)
		im(i)  = ht*mm(i)*0.25d0

	end do
!AD: add for death 
!----------  calcul de u(ti) :  STRATE2 ---------------------------
!    attention the(1)  sont en nz=1
!        donc en ti on a the(i)

	do i=1,ndatedc-1
		do k = 2,n-2
			if ((datedc(i).ge.zi(k-1)).and.(datedc(i).lt.zi(k)))then
				j = k-1
			endif
		end do 
		ht = datedc(i)-zi(j)
		htm= datedc(i)-zi(j-1)
		h2t= datedc(i)-zi(j+2)
		ht2 = zi(j+1)-datedc(i)
		ht3 = zi(j+3)-datedc(i)
		hht = datedc(i)-zi(j-2)
		h = zi(j+1)-zi(j)
		hh= zi(j+1)-zi(j-1)
		h2= zi(j+2)-zi(j)
		h3= zi(j+3)-zi(j)
		h4= zi(j+4)-zi(j)
		h3m= zi(j+3)-zi(j-1)
		h2n=zi(j+2)-zi(j-1)
		hn= zi(j+1)-zi(j-2)
		hh3 = zi(j+1)-zi(j-3)
		hh2 = zi(j+2)-zi(j-2)
		mm3dc(i) = ((4.d0*ht2*ht2*ht2)/(h*hh*hn*hh3))
		mm2dc(i) = ((4.d0*hht*ht2*ht2)/(hh2*hh*h*hn))+((-4.d0*h2t*htm &
		*ht2)/(hh2*h2n*hh*h))+((4.d0*h2t*h2t*ht)/(hh2*h2*h*h2n))
		mm1dc(i) = (4.d0*(htm*htm*ht2)/(h3m*h2n*hh*h))+((-4.d0*htm*ht* &
		h2t)/(h3m*h2*h*h2n))+((4.d0*ht3*ht*ht)/(h3m*h3*h2*h))
		mmdc(i)  = 4.d0*(ht*ht*ht)/(h4*h3*h2*h)
		im3dc(i) = (0.25d0*(datedc(i)-zi(j-3))*mm3dc(i))+(0.25d0*hh2 &
		*mm2dc(i))+(0.25d0*h3m*mm1dc(i))+(0.25d0*h4*mmdc(i))
		im2dc(i) = (0.25d0*hht*mm2dc(i))+(h3m*mm1dc(i)*0.25d0) &
			+(h4*mmdc(i)*0.25d0)
		im1dc(i) = (htm*mm1dc(i)*0.25d0)+(h4*mmdc(i)*0.25d0)
		imdc(i)  = ht*mmdc(i)*0.25d0

	end do
!AD:end	    
	end subroutine vecspliJ  

!========================== VECPEN ==============================
	subroutine vecpenJ(n) 
	
	use tailles
	
	use comon,only:date,datedc,zi,m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m
	
	IMPLICIT NONE
	
	integer,intent(in)::n
	integer::i
	double precision::h,hh,h2,h3,h4,h3m,h2n,hn,hh3,hh2,a3,a2,b2 &
	,c2,a1,b1,c1,a0,x3,x2,x


!*********************************************************************
         
	do i=1,n-3
		h = zi(i+1)-zi(i)
		
		hh= zi(i+1)-zi(i-1)
		h2= zi(i+2)-zi(i)
		h3= zi(i+3)-zi(i)
		h4= zi(i+4)-zi(i)
		h3m= zi(i+3)-zi(i-1)
		h2n=zi(i+2)-zi(i-1)
		hn= zi(i+1)-zi(i-2)
		hh3 = zi(i+1)-zi(i-3)
		hh2 = zi(i+2)-zi(i-2)
		a3 = h*hh*hn*hh3
		a2 = hh2*hh*h*hn
		b2 = hh2*h2n*hh*h
		c2 = hh2*h2*h*h2n
		a1 = h3m*h2n*hh*h
		b1 = h3m*h2*h*h2n
		c1 = h3m*h3*h2*h
		a0 = h4*h3*h2*h
		x3 = zi(i+1)*zi(i+1)*zi(i+1)-zi(i)*zi(i)*zi(i)
		x2 = zi(i+1)*zi(i+1)-zi(i)*zi(i)
		x  = zi(i+1)-zi(i)
		
		m3m3(i) = (192.d0*h/(hh*hn*hh3*hh*hn*hh3))
		m2m2(i) = 64.d0*(((3.d0*x3-(3.d0*x2*(2.d0*zi(i+1)+zi(i-2) &
		))+x*(4.d0*zi(i+1)*zi(i+1)+zi(i-2)*zi(i-2)+4.d0*zi(i+1) &
		*zi(i-2)))/(a2*a2)))
		m2m2(i) = m2m2(i) + 64.d0*(((3.d0*x3-(3.d0*x2*(zi(i+2)  &
		+zi(i-1)+zi(i+1)))+x*(zi(i+2)*zi(i+2)+zi(i-1)*zi(i-1) &
		+zi(i+1)*zi(i+1)+2.d0*zi(i+2)*zi(i-1)+2.d0*zi(i+2) &
		*zi(i+1)+2.d0*zi(i-1)*zi(i+1)))/(b2*b2)))
		m2m2(i) = m2m2(i) +64.d0*((3.d0*x3-(3.d0*x2*(2.d0*zi(i+2) &
		+zi(i)))+x*(4.d0*zi(i+2)*zi(i+2)+zi(i)*zi(i)+4.d0*zi(i+2) &
		*zi(i)))/(c2*c2))
		
		m2m2(i) = m2m2(i) +128.d0*((3.d0*x3-(1.5d0*x2*(zi(i+2) &
		+zi(i-1)+3.d0*zi(i+1)+zi(i-2)))+x*(2.d0*zi(i+1)*zi(i+2) &
		+2.d0*zi(i+1)*zi(i-1)+2.d0*zi(i+1)*zi(i+1)+zi(i-2)*zi(i+2) &
		+zi(i-2)*zi(i-1)+zi(i-2)*zi(i+1)))/(a2*b2))
		m2m2(i) = m2m2(i) + 128.d0*((3.d0*x3-(1.5d0* & 
		x2*(2.d0*zi(i+2)+zi(i)+2.d0*zi(i+1)+zi(i-2)))+x* &
		(4.d0*zi(i+1)*zi(i+2)+2.d0*zi(i+1)*zi(i)+2.d0*zi(i-2) &
		*zi(i+2)+zi(i-2)*zi(i)))/(a2*c2))
		m2m2(i) = m2m2(i) + 128.d0*((3.d0*x3-(1.5d0*x2 &
		*(3.d0*zi(i+2)+zi(i)+zi(i-1)+zi(i+1)))+x*(zi(i+2)*zi(i)+ &
		2.d0*zi(i-1)*zi(i+2)+zi(i)*zi(i-1)+2.d0*zi(i+1)*zi(i+2) &
		+zi(i+1)*zi(i)+2.d0*zi(i+2)*zi(i+2)))/(b2*c2))
		m1m1(i) = 64.d0*((3.d0*x3-(3.d0*x2*(2.d0*zi(i-1)+zi(i+1))) &
		+x*(4.d0*zi(i-1)*zi(i-1)+zi(i+1)*zi(i+1)+4.d0*zi(i-1) &
		*zi(i+1)))/(a1*a1))
		m1m1(i) = m1m1(i) + 64.d0*((3.d0*x3-(3.d0*x2*(zi(i-1)+zi(i) &     
		+zi(i+2)))+x*(zi(i-1)*zi(i-1)+zi(i)*zi(i)+zi(i+2)* &
		zi(i+2)+2.d0*zi(i-1)*zi(i)+2.d0*zi(i-1)*zi(i+2)+2.d0* &
		zi(i)*zi(i+2)))/(b1*b1))
		m1m1(i) = m1m1(i) + 64.d0*((3.d0*x3-(3.d0*x2*(zi(i+3) &
		+2.d0*zi(i)))+x*(zi(i+3)*zi(i+3)+4.d0*zi(i)*zi(i) &
		+4.d0*zi(i+3)*zi(i)))/(c1*c1)) 
		m1m1(i) = m1m1(i) + 128.d0*((3.d0*x3-(1.5d0*x2*(3.d0 &
		*zi(i-1)+zi(i)+zi(i+2)+zi(i+1)))+x*(2.d0*zi(i-1)*zi(i-1) &
		+2.d0*zi(i-1)*zi(i)+2.d0*zi(i-1)*zi(i+2)+zi(i+1)*zi(i-1) &
		+zi(i+1)*zi(i)+zi(i+1)*zi(i+2)))/(a1*b1))
		m1m1(i) = m1m1(i) + 128.d0*((3.d0*x3-(1.5d0*x2*(zi(i+3)+ &
		2.d0*zi(i)+2.d0*zi(i-1)+zi(i+1)))+x*(2.d0*zi(i-1)*zi(i+3) &
		+4.d0*zi(i-1)*zi(i)+zi(i+1)*zi(i+3)+2.d0*zi(i+1)*zi(i))) &
		/(a1*c1))    
		m1m1(i) = m1m1(i) + 128.d0*((3.d0*x3-(1.5d0*x2*(zi(i+3)+3.d0 &
		*zi(i)+zi(i-1)+zi(i+2)))+x*(zi(i-1)*zi(i+3)+2.d0*zi(i-1) &    
		*zi(i)+zi(i+3)*zi(i)+2.d0*zi(i)*zi(i)+zi(i+2)*zi(i+3) &
		+2.d0*zi(i+2)*zi(i)))/(b1*c1))
		mmm(i) = (192.d0*h/(h4*h3*h2*h4*h3*h2))
		m3m2(i) = 192.d0*(((-x3+(0.5d0*x2*(5.d0*zi(i+1)+zi(i-2) &
		))-x*(2.d0*zi(i+1)*zi(i+1)+zi(i+1)*zi(i-2)))/(a3*a2)) &
		+((-x3+(0.5d0*x2*(4.d0*zi(i+1)+zi(i-1)+zi(i+2)))-x* &
		(zi(i+1)*zi(i+2)+zi(i+1)*zi(i-1)+zi(i+1)*zi(i+1)))/(a3*b2)) &
		+((-x3+(0.5d0*x2*(3.d0*zi(i+1)+2.d0*zi(i+2)+zi(i)))-x* &
		(2.d0*zi(i+1)*zi(i+2)+zi(i+1)*zi(i)))/(a3*c2)) )
		m3m1(i) = 192.d0*(((x3-(0.5d0*x2*(4.d0*zi(i+1)+2.d0*zi(i-1) &
		))+x*(2.d0*zi(i+1)*zi(i-1)+zi(i+1)*zi(i+1)))/(a3*a1)) &
		+((x3-(0.5d0*x2*(3.d0*zi(i+1)+zi(i+2)+zi(i-1)+zi(i))) &
		+x*(zi(i+1)*zi(i-1)+zi(i+1)*zi(i)+zi(i+1)*zi(i+2)))/(b1*a3)) &
		+((x3-(0.5d0*x2*(3.d0*zi(i+1)+zi(i+3)+2.d0*zi(i)))+x*(zi(i+1) &
		*zi(i+3)+2.d0*zi(i+1)*zi(i)))/(c1*a3)) )
		m3m(i) = 576.d0*((-(x3/3.d0)+(0.5d0*x2*(zi(i+1)+zi(i))) &
		-x*zi(i+1)*zi(i))/(a3*a0))
		m2m1(i) = 64.d0*((-3.d0*x3+(1.5d0*x2*(2.d0*zi(i-1)+3.d0* &
		zi(i+1)+zi(i-2)))-x*(4.d0*zi(i+1)*zi(i-1)+2.d0*zi(i+1) &
		*zi(i+1)+2.d0*zi(i-2)*zi(i-1)+zi(i-2)*zi(i+1)))/(a2*a1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(zi(i-1)+ &
		zi(i)+zi(i+2)+2.d0*zi(i+1)+zi(i-2)))-x*(2.d0*zi(i+1)*zi(i-1) &
		+2.d0*zi(i+1)*zi(i)+2.d0*zi(i+1)*zi(i+2)+zi(i-2)*zi(i-1)+ &
		zi(i-2)*zi(i)+zi(i-2)*zi(i+2)))/(a2*b1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(zi(i+3)+2.d0 &
		*zi(i)+2.d0*zi(i+1)+zi(i-2)))-x*(2.d0*zi(i+1)*zi(i+3)+4.d0 &
		*zi(i+1)*zi(i)+zi(i-2)*zi(i+3)+2.d0*zi(i-2)*zi(i)))/(a2*c1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2* &
		(3.d0*zi(i-1)+2.d0*zi(i+1)+zi(i+2)))-x*(2.d0*zi(i+2)*zi(i-1) &
		+zi(i+2)*zi(i+1)+2.d0*zi(i-1)*zi(i-1)+3.d0 &
		*zi(i+1)*zi(i-1)+zi(i+1)*zi(i+1)))/(b2*a1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(2.d0 &
		*zi(i-1)+zi(i)+2.d0*zi(i+2)+zi(i+1)))-x*(zi(i+2)*zi(i-1) &
		+zi(i+2)*zi(i)+zi(i+2)*zi(i+2)+zi(i-1)*zi(i-1)+zi(i-1) &
		*zi(i)+zi(i-1)*zi(i+2)+zi(i+1)*zi(i-1)+zi(i+1)*zi(i) &
		+zi(i+1)*zi(i+2)))/(b2*b1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(zi(i+3) &
		+2.d0*zi(i)+zi(i+2)+zi(i-1)+zi(i+1)))-x*(zi(i+2)*zi(i+3) &
		+2.d0*zi(i+2)*zi(i)+zi(i-1)*zi(i+3)+2.d0*zi(i-1)*zi(i) &
		+zi(i+1)*zi(i+3)+2.d0*zi(i+1)*zi(i)))/(b2*c1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(2.d0*zi(i-1) &
		+zi(i+1)+2.d0*zi(i+2)+zi(i)))-x*(4.d0*zi(i+2)*zi(i-1)+2.d0* &
		zi(i+2)*zi(i+1)+2.d0*zi(i)*zi(i-1)+zi(i)*zi(i+1)))/(c2*a1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(zi(i-1) &
		+2.d0*zi(i)+3.d0*zi(i+2)))-x*(2.d0*zi(i+2)*zi(i-1)+2.d0 &
		*zi(i+2)*zi(i)+2.d0*zi(i+2)*zi(i+2)+zi(i)*zi(i-1)+zi(i) &
		*zi(i)+zi(i)*zi(i+2)))/(c2*b1))
		m2m1(i) = m2m1(i) + 64.d0*((-3.d0*x3+(1.5d0*x2*(zi(i+3) &
		+3.d0*zi(i)+2.d0*zi(i+2)))-x*(2.d0*zi(i+2)*zi(i+3)+4.d0 &
		*zi(i+2)*zi(i)+zi(i)*zi(i+3)+2.d0*zi(i)*zi(i)))/(c2*c1))
		m2m(i) = 192.d0*(((x3-(0.5d0*x2*(3.d0*zi(i)+2.d0*zi(i+1) &
		+zi(i-2)))+x*(2.d0*zi(i+1)*zi(i)+zi(i-2)*zi(i)))/(a2*a0)) &
		+((x3-(0.5d0*x2*(3.d0*zi(i)+zi(i+2)+zi(i-1)+zi(i+1))) &
		+x*(zi(i+2)*zi(i)+zi(i-1)*zi(i)+zi(i+1)*zi(i)))/(b2*a0)) &
		+((x3-(0.5d0*x2*(4.d0*zi(i)+2.d0*zi(i+2)))+x*(2.d0*zi(i+2) &
		*zi(i)+zi(i)*zi(i)))/(c2*a0)) )
		m1m(i) = 192.d0*(((-x3+(0.5d0*x2*(3.d0*zi(i)+2.d0*zi(i-1) &
		+zi(i+1)))-x*(2.d0*zi(i-1)*zi(i)+zi(i+1)*zi(i)))/(a1*a0)) &
		+((-x3+(0.5d0*x2*(4.d0*zi(i)+zi(i-1)+zi(i+2))) &
		-x*(zi(i-1)*zi(i)+zi(i)*zi(i)+zi(i+2)*zi(i)))/(b1*a0)) &
		+((-x3+(0.5d0*x2*(5.d0*zi(i)+zi(i+3)))-x*(zi(i+3)*zi(i) &
		+2.d0*zi(i)*zi(i)))/(c1*a0)) )

	end do

	end subroutine vecpenJ






!==========================  SUSP  ====================================
	subroutine suspJ(x,the,n,su,lam,zi)
	
	use tailles
	
	IMPLICIT NONE 
	
	integer,intent(in)::n
	double precision,intent(out)::lam,su
	double precision,dimension(-2:npmax),intent(in)::zi,the
	double precision,intent(in)::x
	integer::j,k,i
	double precision::ht,ht2,h2,som,htm,h2t,h3,h2n,hn, &
	im,im1,im2,mm1,mm3,ht3,hht,h4,h3m,hh3,hh2,mm,im3,mm2 &
	,h,gl,hh

	gl=0.d0
	som = 0.d0
	do k = 2,n+1
		if ((x.ge.zi(k-1)).and.(x.lt.zi(k)))then
			j = k-1
			if (j.gt.1)then
				do i=2,j
					som = som+the(i-4)
				end do  
			endif   
			ht = x-zi(j)
			htm= x-zi(j-1)
			h2t= x-zi(j+2)
			ht2 = zi(j+1)-x
			ht3 = zi(j+3)-x
			hht = x-zi(j-2)
			h = zi(j+1)-zi(j)
			hh= zi(j+1)-zi(j-1)
			h2= zi(j+2)-zi(j)
			h3= zi(j+3)-zi(j)
			h4= zi(j+4)-zi(j)
			h3m= zi(j+3)-zi(j-1)
			h2n=zi(j+2)-zi(j-1)
			hn= zi(j+1)-zi(j-2)
			hh3 = zi(j+1)-zi(j-3)
			hh2 = zi(j+2)-zi(j-2)
			mm3 = ((4.d0*ht2*ht2*ht2)/(h*hh*hn*hh3))
			mm2 = ((4.d0*hht*ht2*ht2)/(hh2*hh*h*hn))+((-4.d0*h2t*htm &
			*ht2)/(hh2*h2n*hh*h))+((4.d0*h2t*h2t*ht)/(hh2*h2*h*h2n))
			mm1 = (4.d0*(htm*htm*ht2)/(h3m*h2n*hh*h))+((-4.d0*htm*ht* &
			h2t)/(h3m*h2*h*h2n))+((4.d0*ht3*ht*ht)/(h3m*h3*h2*h))
			mm  = 4.d0*(ht*ht*ht)/(h4*h3*h2*h)
			im3 = (0.25d0*(x-zi(j-3))*mm3)+(0.25d0*hh2*mm2) &
			+(0.25d0*h3m*mm1)+(0.25d0*h4*mm)
			im2 = (0.25d0*hht*mm2)+(h3m*mm1*0.25d0)+(h4*mm*0.25d0)
			im1 = (htm*mm1*0.25d0)+(h4*mm*0.25d0)
			im  = ht*mm*0.25d0
			gl = som +(the(j-3)*im3)+(the(j-2)*im2)+(the(j-1)*im1)+(the(j)*im)
			lam = (the(j-3)*mm3)+(the(j-2)*mm2)+(the(j-1)*mm1)+(the(j)*mm)
		endif
	end do
   
	if(x.ge.zi(n))then
		som = 0.d0
		do i=1,n+1
			som = som+the(i-3)
		end do
		gl = som
	endif
	
	su  = dexp(-gl)
	
	return
	 
	end subroutine suspJ

!==========================  COSP  ====================================
! calcul les points pour les fonctions 
! et leur bandes de confiance

	subroutine cospJ(x,the,n,y,zi,binf,su,bsup,lbinf,lam,lbsup)
	
	use tailles
	
	IMPLICIT NONE
	
	integer,intent(in)::n
	double precision,intent(in)::x
	double precision,intent(out)::lam,su
	double precision,intent(out)::binf,bsup,lbinf,lbsup
	double precision,dimension(npmax,npmax),intent(in)::y
	double precision,dimension(-2:npmax),intent(in)::the,zi
	integer::j,k,i
	double precision::ht,ht2,h2,som,pm,htm,h2t,h3,h2n,hn, &
	im,im1,im2,mm1,mm3,ht3,hht,h4,h3m,hh3,hh2,mm,im3,mm2, &
	h,gl,hh
      
	gl=0.d0
	som = 0.d0
	do k = 2,n-1
		if ((x.ge.zi(k-1)).and.(x.lt.zi(k)))then
			j = k-1
			if (j.gt.1)then
				do i=2,j
				som = som+the(i-4)
				end do  
			endif   
			ht = x-zi(j)
			htm= x-zi(j-1)
			h2t= x-zi(j+2)
			ht2 = zi(j+1)-x
			ht3 = zi(j+3)-x
			hht = x-zi(j-2)
			h = zi(j+1)-zi(j)
			hh= zi(j+1)-zi(j-1)
			h2= zi(j+2)-zi(j)
			h3= zi(j+3)-zi(j)
			h4= zi(j+4)-zi(j)
			h3m= zi(j+3)-zi(j-1)
			h2n=zi(j+2)-zi(j-1)
			hn= zi(j+1)-zi(j-2)
			hh3 = zi(j+1)-zi(j-3)
			hh2 = zi(j+2)-zi(j-2)
			mm3 = ((4.d0*ht2*ht2*ht2)/(h*hh*hn*hh3))
			mm2 = ((4.d0*hht*ht2*ht2)/(hh2*hh*h*hn))+((-4.d0*h2t*htm &
			*ht2)/(hh2*h2n*hh*h))+((4.d0*h2t*h2t*ht)/(hh2*h2*h*h2n))
			mm1 = (4.d0*(htm*htm*ht2)/(h3m*h2n*hh*h))+((-4.d0*htm*ht* &
			h2t)/(h3m*h2*h*h2n))+((4.d0*ht3*ht*ht)/(h3m*h3*h2*h))
			mm  = 4.d0*(ht*ht*ht)/(h4*h3*h2*h)
			im3 = (0.25d0*(x-zi(j-3))*mm3)+(0.25d0*hh2*mm2) &
			+(0.25d0*h3m*mm1)+(0.25d0*h4*mm)
			im2 = (0.25d0*hht*mm2)+(h3m*mm1*0.25d0)+(h4*mm*0.25d0)
			im1 = (htm*mm1*0.25d0)+(h4*mm*0.25d0)
			im  = ht*mm*0.25d0
			gl = som +(the(j-3)*im3)+(the(j-2)*im2)+(the(j-1)*im1)+(the(j)*im)
			lam = (the(j-3)*mm3)+(the(j-2)*mm2)+(the(j-1)*mm1)+(the(j)*mm)
		endif
	end do
   
	if(x.ge.zi(n))then
		som = 0.d0
		do i=1,n
			som = som+the(i-3)
		end do
		gl = som
	endif

	call confJ(x,j,n,y,pm,zi)

	binf = dexp(-gl + 1.96d0*pm)
	su  = dexp(-gl)
	bsup = dexp(-gl - 1.96d0*pm)

	call conf1J(x,j,n,y,pm,zi)
	lbinf = lam - 1.96d0*pm
	lbsup = lam + 1.96d0*pm
!         write(*,*)'lbinf apres conf1',lbinf,lam,pm

	return

	end subroutine cospJ
	 
	 
!=====================  CONF1  =============================


	subroutine  conf1J(x,ni,n,y,pm,zi)
	
	use tailles
	
	IMPLICIT NONE  
	
	integer,intent(in)::ni,n
	double precision,intent(in)::x
	double precision,dimension(-2:npmax),intent(in)::zi
	double precision,dimension(npmax,npmax),intent(in)::y
	double precision,intent(out)::pm
	integer::i,j
	double precision::res,mmspJ
	double precision,dimension(npmax)::vecti,aux

      
           
	do i=1,n
		vecti(i) = mmspJ(x,ni,i,zi)
	end do
	
	do i=1,n
		aux(i) = 0.d0
		do j=1,n
			aux(i) = aux(i) - y(i,j)*vecti(j)
		end do
	end do 


	res = 0.d0
	do i=1,n
		res = res + aux(i)*vecti(i)
	end do
	
	res=-res 
	pm = dsqrt(res)
	
	end subroutine  conf1J
	 
!=====================  CONF  =============================

	subroutine  confJ(x,ni,n,y,pm,zi)
	
	use tailles
	
	IMPLICIT NONE  
	
	integer,intent(in)::ni,n
	double precision,intent(in)::x
	double precision,dimension(-2:npmax),intent(in)::zi
	double precision,dimension(npmax,npmax),intent(in)::y
	double precision,intent(out)::pm
	integer::i,j
	double precision::res,ispJ
	double precision,dimension(52)::vecti,aux
	
	do i=1,n
	vecti(i) = ispJ(x,ni,i,zi)
	end do   

	do i=1,n
	aux(i) = 0.d0
	do j=1,n
		aux(i) = aux(i) - y(i,j)*vecti(j)
	end do
	end do   

	res = 0.d0
	do i=1,n
	res = res + aux(i)*vecti(i)
	end do
	res=-res
	pm = dsqrt(res)
               
	end subroutine  confJ


!==========================   ISP   ==================================

	double precision function ispJ(x,ni,ns,zi)
	
	use tailles
	
	IMPLICIT NONE  
	
	integer,intent(in)::ni,ns
	double precision,intent(in)::x
	double precision,dimension(-2:npmax),intent(in)::zi
	double precision::val,mmspJ



	if(x.eq.zi(ni))then
		if(ni.le.ns-3)then
			val = 0.d0
			else
				if(ni.le.ns-2)then
					val = ((zi(ni)-zi(ni-1))*mmspJ(x,ni,ns,zi))*0.25d0
				else
					if (ni.eq.ns-1)then
						val = ((zi(ni)-zi(ni-2))*mmspJ(x,ni,ns,zi)+ &
						(zi(ni+3)-zi(ni-1))*mmspJ(x,ni,ns+1,zi))*0.25d0
					else
						if(ni.eq.ns)then
							val = ((zi(ni)-zi(ni-3))*mmspJ(x,ni,ns,zi)+ &
							(zi(ni+2)-zi(ni-2))*mmspJ(x,ni,ns+1,zi) &
							+(zi(ni+3)-zi(ni-1))*mmspJ(x,ni,ns+2,zi))*0.25d0
							else
								val = 1.d0
							endif
						endif
				endif   
		endif
	else   
		if(ni.lt.ns-3)then
			val = 0.d0
		else
			if(ni.eq.ns-3)then
				val = (x-zi(ni))*mmspJ(x,ni,ns,zi)*0.25d0
			else  
				if(ni.eq.ns-2)then
					val = ((x-zi(ni-1))*mmspJ(x,ni,ns,zi)+ &
					(zi(ni+4)-zi(ni))*mmspJ(x,ni,ns+1,zi))*0.25d0
				else   
					if (ni.eq.ns-1)then
						val =((x-zi(ni-2))*mmspJ(x,ni,ns,zi)+ &
						(zi(ni+3)-zi(ni-1))*mmspJ(x,ni,ns+1,zi) &
						+(zi(ni+4)-zi(ni))*mmspJ(x,ni,ns+2,zi))*0.25d0
					else
						if(ni.eq.ns)then
							val =((x-zi(ni-3))*mmspJ(x,ni,ns,zi)+ &
							(zi(ni+2)-zi(ni-2))*mmspJ(x,ni,ns+1,zi) &
							+(zi(ni+3)-zi(ni-1))*mmspJ(x,ni,ns+2,zi) &
							+(zi(ni+4)-zi(ni))*mmspJ(x,ni,ns+3,zi))*0.25d0
						else
							val = 1.d0
						endif
					endif
				endif
			endif
		endif 
	endif
	  
	ispJ = val
	
	return
	
	end function ispJ
	
!==========================  MMSP   ==================================

	double precision function mmspJ(x,ni,ns,zi)
	
	use tailles
	
	IMPLICIT NONE 
	
	integer,intent(in)::ni,ns
	double precision,intent(in)::x
	double precision,dimension(-2:npmax),intent(in)::zi
	double precision::val

	if(ni.lt.ns-3)then
		val = 0.d0
	else
		if(ns-3.eq.ni)then
			if(x.eq.zi(ni))then
				val = 0.d0
			else  
				val = (4.d0*(x-zi(ni))*(x-zi(ni)) &
				*(x-zi(ni)))/((zi(ni+4)-zi(ni))*(zi(ni+3) &
				-zi(ni))*(zi(ni+2)-zi(ni))*(zi(ni+1)-zi(ni)))
			endif
		else 
			if(ns-2.eq.ni)then
				if(x.eq.zi(ni))then
					val = (4.d0*(zi(ni)-zi(ni-1))*(zi(ni)-zi(ni-1))) &
					/((zi(ni+3)-zi(ni-1))*(zi(ni+2)-zi(ni-1)) &
					*(zi(ni+1)-zi(ni-1)))
				else  
					val = (4.d0*(x-zi(ni-1))*(x-zi(ni-1)) &
					*(zi(ni+1)-x))/((zi(ni+3)-zi(ni-1))*(zi(ni+2) &
					-zi(ni-1))*(zi(ni+1)-zi(ni-1))*(zi(ni+1)-zi(ni))) &
					+   (4.d0*(x-zi(ni-1))*(x-zi(ni)) &
					*(zi(ni+2)-x))/((zi(ni+3)-zi(ni-1))*(zi(ni+2) &
					-zi(ni))*(zi(ni+1)-zi(ni))*(zi(ni+2)-zi(ni-1))) &
					+   (4.d0*(x-zi(ni))*(x-zi(ni)) &
					*(zi(ni+3)-x))/((zi(ni+3)-zi(ni-1))*(zi(ni+3) &
					-zi(ni))*(zi(ni+2)-zi(ni))*(zi(ni+1)-zi(ni)))
				endif
			else   
				if (ns-1.eq.ni)then
					if(x.eq.zi(ni))then
						val = (4.d0*((zi(ni)-zi(ni-2))*(zi(ni+1) &
						-zi(ni)))/((zi(ni+2)-zi(ni-2))*(zi(ni+1) &
						-zi(ni-1))*(zi(ni+1)-zi(ni-2)))) &
						+((4.d0*((zi(ni)-zi(ni-1))*(zi(ni+2)-zi(ni))) &
						/((zi(ni+2)-zi(ni-2))*(zi(ni+2)-zi(ni-1)) &
						*(zi(ni+1)-zi(ni-1)))))
					else
						val = (4.d0*((x-zi(ni-2))*(zi(ni+1) &
						-x)*(zi(ni+1)-x))/((zi(ni+2) &
						-zi(ni-2))*(zi(ni+1)-zi(ni-1))*(zi(ni+1)- &
						zi(ni))*(zi(ni+1)-zi(ni-2)))) &
						+((4.d0*((x-zi(ni-1))*(zi(ni+2)-x)  &
						*(zi(ni+1)-x))/((zi(ni+2)-zi(ni-2)) &
						*(zi(ni+2)-zi(ni-1))*(zi(ni+1)-zi(ni-1))* &
						(zi(ni+1)-zi(ni))))) &
						+((4.d0*((zi(ni+2)-x)*(zi(ni+2)-x) &
						*(x-zi(ni)))/((zi(ni+2)-zi(ni-2)) &
						*(zi(ni+2)-zi(ni))*(zi(ni+2)-zi(ni-1))* &
						(zi(ni+1)-zi(ni)))))
					endif 
				else
					if(ni.eq.ns)then
							if(x.eq.zi(ni))then
							val =(4.d0*(x-zi(ni+1))*(x &
							-zi(ni+1))/((zi(ni+1)-zi(ni-1))*(zi(ni+1) &
							-zi(ni-2))*(zi(ni+1)-zi(ni-3))))
						else   
							val =(4.d0*(x-zi(ni+1))*(x &
							-zi(ni+1))*(zi(ni+1)-x)/((zi(ni+1) &
							-zi(ni-1))*(zi(ni+1)-zi(ni-2))*(zi(ni+1) &
							-zi(ni))*(zi(ni+1)-zi(ni-3))))
						endif
					else
						val = 0.d0
					endif
				endif
			endif
		endif
	endif

	mmspJ = val
	
	return
	
	end function mmspJ

!================== multiplication de matrice  ==================

! multiplie A par B avec le resultat dans C

	subroutine multiJ(A,B,IrowA,JcolA,JcolB,C)
!     remarque :  jcolA=IrowB
	use tailles
	
	IMPLICIT NONE
	
	integer,intent(in)::IrowA,JcolA,JcolB
	double precision,dimension(npmax,npmax),intent(in):: A,B
	double precision,dimension(npmax,npmax),intent(out)::C       
	integer::i,j,k
	double precision::sum

	do I=1,IrowA
		do J=1,JcolB
			sum=0
			do K=1,JcolA
				sum=sum+A(I,K)*B(K,J)
			end do
			C(I,J)=sum
		end do
	end do
	
	return
	
	end subroutine multiJ
!====================================================================
!============================    GAMMA      ==============================

!       function qui calcule le log de  Gamma
	double precision function gammaJ(xx)
	
	use donnees,only:cof,stp,half,one,fpf 
	
	implicit none
	
	integer::j
	double precision,intent(in)::xx
            
	
	double precision::x,tmp,ser
	
	x = xx - one
	tmp = x + fpf
	tmp = (x+half)*dlog(tmp) - tmp
	ser = one
	do j = 1,6
		x = x + one
		ser = ser + cof(j)/x
	end do
	gammaJ = tmp + dlog(stp*ser)
	
	return
	
	end function gammaJ
	

!======================================================

!==================================================================
!==================================================================
!
  
!================================================

	double precision function func1J(frail) 
! calcul de l integrant, pour un effet aleatoire donn� frail et un groupe donne auxig (cf funcpa)      
	use tailles
	
	use comon,only:auxig,alpha,theta,aux1,aux1,mi
	
	IMPLICIT NONE

	double precision,intent(in)::frail

!============================================================
	
	func1J = (frail**(alpha*mi(auxig)+1./theta-1.))* &
		dexp(-(frail**alpha) *aux1(auxig))*dexp(-frail/theta)
	
	return
	
	end function func1J
!==================================================================

!================================================

	double precision function func2J(frail) 
! calcul de l integrant, pour un effet aleatoire donn� frail et un groupe donne auxig (cf funcpa)      
	use tailles
	
	use comon,only:auxig,ALPHA,theta,aux2
	
	IMPLICIT NONE
	
	double precision,intent(in)::frail
	double precision::gammaJ
            
!============================================================
      
	func2J = dexp(-(frail**alpha)*aux2(auxig))*dexp(-frail/theta)*(frail) &
	/(exp(gammaJ(1.d0/theta))*(theta**(1./theta)))
		
	return
	
	end function func2J
	
!==================================================================

	double precision function func3J(frail) 
! calcul de l integrant, pour un effet aleatoire donn� frail et un groupe donne auxig (cf funcpa)      
      	use tailles
	use comon,only:nig,auxig,alpha,theta,res1,res3,aux1, &
        cdc  
	
	IMPLICIT NONE 

	double precision,intent(in)::frail
!      double precision func3

	func3J = (nig(auxig)+ alpha*cdc(auxig)+ 1./theta-1.)*dlog(frail) &
		- frail*(res1(auxig)-res3(auxig)) &!res3=0 si AG=0
		- (frail**alpha)*(aux1(auxig))- frail/theta

	
	func3J = exp(func3J)
	
	return
	
	end function func3J
! YAS : FUNC4 INTERVIENT DANS LE CALCUL DE INTEGRALE4

!==================================================================



	
	SUBROUTINE gaulagJ(ss,choix) 
	
	use tailles
	use comon,only:auxig,typeof
	use donnees,only:w,x,w1,x1
	
	IMPLICIT NONE
	
	integer,intent(in)::choix
	double precision,intent(out):: ss
	double precision ::auxfunca,func1J,func2J,func3J
	external :: func1J,func2J,func3J
! gauss laguerre
! func1 est l int�grant, ss le r�sultat de l integrale sur 0 ,  +infty
	integer :: j

	    
	ss=0.d0 
	if (typeof == 0)then  
! Will be twice the average value of the function,since the ten
! wei hts (five numbers above each used twice) sum to 2.
		do j=1,20
			if (choix.eq.1) then !integrale 1
				auxfunca=func1J(x(j))
				ss = ss+w(j)*(auxfunca)

			else                   !choix=2, survie marginale, vraie troncature
				if (choix.eq.2) then 
					auxfunca=func2J(x(j))
					ss = ss+w(j)*(auxfunca)
				else                   !choix=3, AG model
					if (choix.eq.3) then
						auxfunca=func3J(x(j))
						ss = ss+w(j)*(auxfunca)
					endif
				endif
			endif
		end do
		
	else
		do j=1,32
			if (choix.eq.1) then !integrale 1
				auxfunca=func1j(x1(j))
				ss = ss+w1(j)*(auxfunca)
			else                   !choix=2, survie marginale, vraie troncature
				if (choix.eq.2) then 
					auxfunca=func2j(x1(j))
					ss = ss+w1(j)*(auxfunca)
				else                   !choix=3, AG model
					if (choix.eq.3) then
						auxfunca=func3j(x1(j))
						ss = ss+w1(j)*(auxfunca)
					endif
				endif
			endif	
	
		end do
	end if
	
	return
	
	END subroutine gaulagJ



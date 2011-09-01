
	
	module share
	double precision,dimension(:,:),allocatable,save::HI
	end module share

	subroutine frailpenal(nsujetAux,ngAux,icenAux,nstAux,effetAux, &
	nzAux,ax1,ax2,tt0Aux,tt1Aux,icAux,groupeAux, &
	nvaAux,strAux,vaxAux,AGAux,noVar,maxitAux,irep1, &
	np,b,H_hessOut,HIHOut,resOut,traceLCV,x1Out,lamOut,suOut, &
	x2Out,lam2Out,su2Out,ni,cpt,ier,k0,ddl)

!
! Obs: noVar=0 indicates no variables but I need to pass all 0's in vaxAux
	use parameters
	use tailles
	use share
	use comon
	use optim
	
	implicit none

	integer::groupe,ij,kk,j,k,nz,n,np,cpt,ii,iii,ver,cptstr1,cptstr2, &
	i,ic,ni,ier,istop,cptni,cptni1,cptni2,ibou,nbou2,id,cptbiais,l, &
	icen,irep1,nvacross,nstcross,effetcross
	integer,dimension(nvaAux)::filtre 
	integer,dimension(nsujetAux)::stracross
	double precision,dimension(nvaAux)::vax
	double precision::tt0,tt1
	double precision::h,ax1,ax2,res,min,max,maxt,str
	double precision,dimension(2)::auxkappa,k0,res01
	double precision,dimension(2*nsujetAux)::aux
	double precision,dimension(np*(np+3)/2)::v
	double precision,dimension(np)::b
	double precision,dimension(np,np)::HIH,IH	
	!******************************************   Add JRG January 05
	integer::ss,sss,noVar,AGAux,maxitAux,nsujetAux,ngAux,icenAux,nstAux,effetAux, &
	nzAux,nvaAux
	double precision::resOut
	double precision,dimension(nsujetAux)::tt0Aux,tt1Aux
	integer,dimension(nsujetAux)::icAux,groupeAux
	double precision,dimension(nsujetAux)::strAux
	double precision,dimension(nsujetAux,nvaAux)::vaxAux
	double precision,dimension(np,np)::H_hessOut,HIHOut
	double precision,dimension(99)::x1Out,x2Out
	double precision,dimension(99,3)::lamOut,suOut,lam2Out,su2Out
	!*******************************************  Add JRG May 05 (Cross-validation)	
	double precision::auxi,ax,bx,cx,tol,ddl,fa,fb,fc,goldens,estimvs, &
	xmin1,xmin2
	double precision,dimension(np,np)::y  
!AD:add
	double precision,intent(out)::traceLCV
	double precision::ca,cb,dd,funcpas
	external::funcpas
!AD:	
	epsa=1.d-3
	epsb=1.d-3
	epsd=1.d-3
	model=4	
	npmax=np

	NSUJETMAX=nsujetAux
	allocate(t0(nsujetmax),t1(nsujetmax),c(nsujetmax),nt0(nsujetmax),nt1(nsujetmax),stra(nsujetmax), &
	g(nsujetmax))

	c=0
	nt0=0
	nt1=0
	g=0 
		
	ndatemax=2*nsujetAux
	allocate(date(ndatemax),mm3(ndatemax),mm2(ndatemax),mm1(ndatemax),mm(ndatemax),im3(ndatemax), &
	im2(ndatemax),im1(ndatemax),im(ndatemax))
	
	date=0.d0
	mm=0.d0
	mm1=0.d0
	mm2=0.d0
	mm3=0.d0
		
	ngmax=ngAux
	allocate(nig(ngmax))
	nig=0
	
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	j=0
	nbou2=0
	id=1	
	cptni=0
	cptni1=0
	cptni2=0
	cptbiais=0
!
!  --------- Added January 05 JRG  
!

	pe=0.d0
	nsujet=0

	ndate=0
	nst=0    
	ibou=1  
	ij=0
	kk=0	
	ni=0
	cpt=0  

	b=0.d0
	resOut=0.d0     

	nsujet=nsujetAux
	ng=ngAux
	icen=icenAux
	nst=nstAux
	effet=effetAux 
	nz=nzAux

	nvarmax=nvaAux
		
	if (noVar.eq.1) then 
		do i=1,nvaAux
			filtre(i)=0
		enddo  
		nva=0  
	else
		do i=1,nvaAux
			filtre(i)=1
		enddo  
		nva=nvaAux  
	end if  

	
	ver=nvaAux
	nvarmax=ver
	allocate(ve(nsujetmax,nvarmax))

	ve=0.d0
	res=0.d0    
	v=0.d0
 
	AG=AGAux
	maxiter=maxitAux 
	
	istop=0
   
!**************************************************
!**************************************************
!********************* prog spline****************

	res01=0.d0
     
!------------  lecture fichier -----------------------

	maxt = 0.d0
	
	cpt = 0
	k = 0
	cptstr1 = 0
	cptstr2 = 0

	do i = 1,nsujet 
		str=1
		if(nst.eq.2)then                     
			tt0=tt0Aux(i)
			tt1=tt1Aux(i)
			ic=icAux(i)
			groupe=groupeAux(i)
			str=strAux(i)
			
			do j=1,nva
				vax(j)=vaxAux(i,j)  
			enddo
		else 
			
			tt0=tt0Aux(i)
			tt1=tt1Aux(i)
			ic=icAux(i)
			groupe=groupeAux(i)
			
			do j=1,nva
				vax(j)=vaxAux(i,j)  
			enddo
		endif
		k = k +1


!     essai sans troncature
!------------------   observation c=1
		if(ic.eq.1)then
			cpt = cpt + 1
			c(k)=1
			
			if(str.eq.1)then
				stra(k) = 1
				cptstr1 = cptstr1 + 1
			else
				if(str.eq.2)then
					stra(k) = 2
					cptstr2 = cptstr2 + 1
				endif
			endif
			
			t0(k) = tt0
			t1(k) = tt1
			g(k) = groupe

! nb de dc dans un groupe
			nig(groupe) = nig(groupe)+1 


			iii = 0
			do ii = 1,ver
				if(filtre(ii).eq.1)then
				iii = iii + 1
				ve(i,iii) = vax(ii)	
				endif
			end do   

		else 
!------------------   censure a droite  c=0
			if(ic.eq.0)then
				c(k) = 0 
				if(str.eq.1)then
					stra(k) = 1
					cptstr1 = cptstr1 + 1
				else
					if(str.eq.2)then
						stra(k) = 2
						cptstr2 = cptstr2 + 1
					endif
				endif
				iii = 0
                         
		
				do ii = 1,ver
					if(filtre(ii).eq.1)then
						iii = iii + 1
						ve(i,iii) =vax(ii)
					endif
				end do 
                      
              
				t0(k) =  tt0
				t1(k) = tt1
				g(k) = groupe
			endif
		endif
		
		if (maxt.lt.t1(k))then
			maxt = t1(k)
		endif

	end do 

! %%%%%%%%%%%%% SANS EFFET ALEATOIRE %%%%%%%%%%%%%%%%%%%%%%%%% 

	nsujet = k
	
	nz1=nz
	nz2=nz
	
	if(nz.gt.20)then
		nz = 20
	endif
	
	if(nz.lt.4)then
		nz = 4
	endif



!***************************************************
!-------------- zi- ----------------------------------

!      construire vecteur zi (des noeuds)

	min = 1.d-10
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
	
	nzmax=nz+3
	allocate(zi(-2:nzmax))
	ndate = k

         
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

 
!--------- affectation nt0,nt1----------------------------

	do i=1,nsujet 
		if(t0(i).eq.0.d0)then
			nt0(i) = 0
		endif
		
		do j=1,ndate
			if(date(j).eq.t0(i))then
				nt0(i)=j
			endif
			
			if(date(j).eq.t1(i))then
				nt1(i)=j
			endif
		end do
	end do 

!--------- affectation des vecteurs de splines -----------------
           
	n  = nz+2

	call vecsplis(n,ndate) 
	
	allocate(m3m3(nzmax),m2m2(nzmax),m1m1(nzmax),mmm(nzmax),m3m2(nzmax),m3m1(nzmax),m3m(nzmax), &
	m2m1(nzmax),m2m(nzmax),m1m(nzmax))
	
	call vecpens(n)

	allocate(H_hess(npmax,npmax),Hspl_hess(npmax,npmax),hess(npmax,npmax), &
	I_hess(npmax,npmax),HI(npmax,npmax))

	H_hess=0.d0
	I_hess=0.d0
	Hspl_hess=0.d0
	hess=0.d0

!------ initialisation des parametres
              
	b=1.d-1
!    Esto se cambia ya que ahora xmin1 es kappa1
 
      
	xmin1=ax1 
	if(nst.eq.2)then
		xmin2 = ax2
	else
		xmin2 = 0.d0 
	endif


!***********************************************************
!************** NEW : cross validation  ***********************
!       sur une seule strate, sans var expli , sans frailties ****
!***********************************************************
         
	nvacross=nva !pour la recherche du parametre de lissage sans var expli
	nva=0
	effetcross=effet
	effet=0
	nstcross=nst
	nst=1

	do l=1,nsujet  
		stracross(l)=stra(l)
	end do
	
	do l=1,nsujet  
		stra(l)=1
	end do
        	
	if(irep1.eq.1)then   !pas recherche du parametre de lissage

		xmin1 = dsqrt(xmin1)
		auxi = estimvs(xmin1,n,b,y,ddl,ni,res)
	
		if (ni.ge.maxiter) then

			do i=1,nz+2
				b(i)=1.d-1
			end do 
			    
			xmin1 = sqrt(10.d0)*xmin1
			auxi = estimvs(xmin1,n,b,y,ddl,ni,res)
			if (ni.lt.maxiter) then

			else
				do i=1,nz+2
					b(i)=1.d-1
				end do   
				
				xmin1 = sqrt(10.d0)*xmin1
				auxi = estimvs(xmin1,n,b,y,ddl,ni,res)
				if (ni.lt.maxiter) then
	
				endif   
			endif
		else

		endif
	            
!---------------------------------------------------
	else                   !recherche du parametre de lissage
            
		if(xmin1.le.0.d0)then
			xmin1 = 1.d0
		endif  
		xmin1 = dsqrt(xmin1)
	
		auxi = estimvs(xmin1,n,b,y,ddl,ni,res)

		if(ddl.gt.-2.5d0)then

			xmin1 = dsqrt(xmin1)
		
			auxi = estimvs(xmin1,n,b,y,ddl,ni,res)
		
			if(ddl.gt.-2.5d0)then
				xmin1 = dsqrt(xmin1)
				auxi = estimvs(xmin1,n,b,y,ddl,ni,res)

				if(ddl.gt.-2.5d0)then
					xmin1 = dsqrt(xmin1)
					auxi = estimvs(xmin1,n,b,y,ddl,ni,res)

					if(ddl.gt.-2.5d0)then
						xmin1 = dsqrt(xmin1)
						auxi = estimvs(xmin1,n,b,y,ddl,ni,res)
			
						if(ddl.gt.-2.5d0)then
							xmin1 = dsqrt(xmin1)
						endif   
					endif   
				endif   
			endif
		endif 
	
		if (ni.ge.maxiter) then
			do i=1,nz+2
				b(i)=1.d-1
			end do     
			xmin1 = sqrt(10.d0)*xmin1
			auxi = estimvs(xmin1,n,b,y,ddl,ni,res)

			if (ni.ge.maxiter) then
				do i=1,nz+2
				b(i)=1.d-1
			end do     
				xmin1 = sqrt(10.d0)*xmin1
			endif
		endif 
		
		ax = xmin1
		bx = xmin1*dsqrt(1.5d0)  

		call mnbraks(ax,bx,cx,fa,fb,fc,b,n)
	
		tol = 0.001d0
	
		res = goldens(ax,bx,cx,tol,xmin1,n,b,y,ddl)

		auxkappa(1)=xmin1*xmin1
		auxkappa(2)=0.d0
	
		call marq98j(auxkappa,b,n,ni,v,res,ier,istop,effet,ca,cb,dd,funcpas)
		if ((istop .eq. 4).or.(res .eq. -1.d9)) then
			goto 1000
		end if		
!AD:	
!	if (istop.eq.4) goto 1000
!AD:	
	endif   

	nva=nvacross ! pour la recherche des parametres de regression
	nst=nstcross ! avec stratification si n�cessaire
	effet=effetcross ! avec effet initial
	
	do l=1,nsujet  
		stra(l)=stracross(l) !r�tablissement stratification
	end do


	k0(1) = xmin1*xmin1
	if(nst.eq.2)then
		k0(2) = xmin2
	endif

!------------  indicateur d'effet aleatoire ou non dans le modele


	call marq98j(k0,b,np,ni,v,res,ier,istop,effet,ca,cb,dd,funcpas)
	if ((istop .eq. 4).or.(res .eq. -1.d9)) then
		goto 1000
	end if	
!	deallocate(mm3,mm2,mm1,mm,im3,im2,im1,im,m3m3,m2m2,m1m1,mmm,m3m2,m3m1, &
!	m3m,m2m1,m2m,m1m,stra,ve,g,nig)
!AD:	
!	if (istop.eq.4) goto 1000
!AD:
	
	j=(np-nva)*(np-nva+1)/2       

	call multis(I_hess,H_hess,np,np,np,IH)
	call multis(H_hess,IH,np,np,np,HIH)

	if(effet.eq.1)then
		j=(np-nva)*(np-nva+1)/2
	endif
          
	if(effet.eq.1.and.ier.eq.-1)then
		v((np-nva)*(np-nva+1)/2)=10.d10
	endif
           
	res01(effet+1)=res

	j=(np-nva)*(np-nva+1)/2

! --------------  Lambda and survival estimates JRG January 05

	call distances(nz1,nz2,b,effet,x1Out,lamOut,suOut,x2Out,lam2Out,su2Out)      

	resOut=res
	
!AD:add LCV
!     calcul de la trace, pour le LCV (likelihood cross validation)
	traceLCV=0.d0
	call multis(H_hess,I_hess,np,np,np,HI)
	
	do i =1,np
		traceLCV = traceLCV + HI(i,i)
	end do 
	
	traceLCV = (traceLCV - resnonpen) / nsujet
!AD:end

	do ss=1,npmax
		do sss=1,npmax
			HIHOut(ss,sss) = HIH(ss,sss)
			H_hessOut(ss,sss)= H_hess(ss,sss)
		end do  
	end do

!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
! 
!    Bias and Var eliminated  
!
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!AD:
1000    continue
!	if(istop.eq.4)then
!		ier=12
!	end if
!AD
	deallocate(date,zi,t0,t1,c,nt0,nt1,I_hess,H_hess,Hspl_hess,hess,HI)
	deallocate(mm3,mm2,mm1,mm,im3,im2,im1,im,m3m3,m2m2,m1m1,mmm,m3m2,m3m1, &
	m3m,m2m1,m2m,m1m,stra,ve,g,nig)	
    
  
	return     

	
	end subroutine frailpenal
      
  
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC


!CCCCCCCCCCC!**********SUBROUTINES******  CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC



!========================== VECSPLI ==============================
	subroutine vecsplis(n,ndate) 

	use tailles,only:ndatemax,NSUJETMAX,npmax,nvarmax
	use comon,only:ve,date,zi,mm3,mm2,mm1,mm,im3,im2,im1,im

	implicit none
	
	integer::n,ndate,i,j,k
	double precision::ht,htm,h2t,ht2,ht3,hht,h,hh,h2,h3,h4,h3m,h2n,hn,hh3,hh2	

!---------  calcul de u(ti) ---------------------------

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
		im2(i) = (0.25d0*hht*mm2(i))+(h3m*mm1(i)*0.25d0)+(h4*mm(i)*0.25d0)
		im1(i) = (htm*mm1(i)*0.25d0)+(h4*mm(i)*0.25d0)
		im(i)  = ht*mm(i)*0.25d0

	end do
	
	end subroutine vecsplis
	
!========================== VECPEN ==============================
	subroutine vecpens(n) 
	use tailles,only:ndatemax,npmax
	use comon,only:date,zi,m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m
	
	implicit none
		
	integer::n,i
	double precision::h,hh,h2,h3,h4,h3m,h2n,hn,hh3,hh2
	double precision::a3,a2,b2,c2,a1,b1,c1,a0,x3,x2,x
     
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
		))+x*(4.d0*zi(i+1)*zi(i+1)+zi(i-2)*zi(i-2)+4.d0*zi(i+1)*zi(i-2)))/(a2*a2)))
		m2m2(i) = m2m2(i) + 64.d0*(((3.d0*x3-(3.d0*x2*(zi(i+2) &
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
		(2.d0*zi(i+1)*zi(i+2)+zi(i+1)*zi(i)))/(a3*c2)))
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
		+2.d0*zi(i)*zi(i)))/(c1*a0)))
	
	end do
	
	end subroutine vecpens




!========================          FUNCPA          ====================
	double precision function funcpas(b,np,id,thi,jd,thj,k0)
	use tailles
	use comon,only:m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m, &
	mm3,mm2,mm1,mm,im3,im2,im1,im,date,zi,t0,t1,c,nt0,nt1,nsujet,nva,ndate, &
	nst,stra,ve,pe,effet,nz1,nz2,ng,g,nig,AG,resnonpen

	
	implicit none
	
! *** NOUVELLLE DECLARATION F90 :
	
	integer::nb,n,np,id,jd,i,j,k,vj,cptg,l
	integer,dimension(ngmax)::cpt
	double precision::thi,thj,pe1,pe2,dnb,sum,theta,inv,som1,som2,res,vet,h1
	double precision,dimension(-2:npmax)::the1,the2
	double precision,dimension(np)::b,bh
	double precision,dimension(ngmax)::res1,res2,res3
	double precision,dimension(2)::k0 
	double precision,dimension(ndatemax)::dut1,dut2
	double precision,dimension(0:ndatemax)::ut1,ut2
!	logical::isnan
	
	j=0
	theta=0.d0
	do i=1,np
		bh(i)=b(i)
	
	end do 

	if (id.ne.0) bh(id)=bh(id)+thi
	if (jd.ne.0) bh(jd)=bh(jd)+thj    
	
	n = (np-nva-effet)/nst
          
	do i=1,n
		the1(i-3)=(bh(i))*(bh(i))
		j = n+i 
		if (nst.eq.2) then
			the2(i-3)=(bh(j))*(bh(j))
		endif
	end do


	if(effet.eq.1) then
		theta = bh(np-nva)*bh(np-nva)
	endif
!---------  calcul de ut1(ti) et ut2(ti) ---------------------------
!    attention the(1)  sont en nz=1
!        donc en ti on a the(i)

	vj = 0
	som1 = 0.d0
	som2 = 0.d0
	dut1(1) = (the1(-2)*4.d0/(zi(2)-zi(1)))

	dut2(1) = (the2(-2)*4.d0/(zi(2)-zi(1)))
	ut1(1) = the1(-2)*dut1(1)*0.25d0*(zi(1)-zi(-2))
	ut2(1) = the2(-2)*dut2(1)*0.25d0*(zi(1)-zi(-2))
	ut1(0) = 0.d0
	ut2(0) = 0.d0
	do i=2,ndate-1
		do k = 2,n-2
			if (((date(i)).ge.(zi(k-1))).and.(date(i).lt.zi(k)))then
				j = k-1
				if ((j.gt.1).and.(j.gt.vj))then
					som1 = som1+the1(j-4)
					som2 = som2+the2(j-4)
					vj  = j
				endif   
			endif
		end do 
		
		ut1(i) = som1 +(the1(j-3)*im3(i))+(the1(j-2)*im2(i)) &
		+(the1(j-1)*im1(i))+(the1(j)*im(i))
		dut1(i) = (the1(j-3)*mm3(i))+(the1(j-2)*mm2(i)) &
		+(the1(j-1)*mm1(i))+(the1(j)*mm(i))
	
		if(nst.eq.2)then
			ut2(i) = som2 +(the2(j-3)*im3(i))+(the2(j-2)*im2(i)) &
			+(the2(j-1)*im1(i))+(the2(j)*im(i))
			dut2(i) = (the2(j-3)*mm3(i))+(the2(j-2)*mm2(i)) &
			+(the2(j-1)*mm1(i))+(the2(j)*mm(i)) 
		endif
            
	end do

	i = n-2
	h1 = (zi(i)-zi(i-1))
	ut1(ndate)=som1+the1(i-4)+the1(i-3)+the1(i-2)+the1(i-1)
	ut2(ndate)=som2+the2(i-4)+the2(i-3)+the2(i-2)+the2(i-1)
	dut1(ndate) = (4.d0*the1(i-1)/h1)
	dut2(ndate) = (4.d0*the2(i-1)/h1)


!-------------------------------------------------------
!--------- calcul de la vraisemblance ------------------
!--------------------------------------------------------

!--- avec ou sans variable explicative  ------cc

	do k=1,ng
		res1(k) = 0.d0
		res2(k) = 0.d0
		res3(k) = 0.d0
		cpt(k) = 0
	end do

!*******************************************     
!---- sans effet aleatoire dans le modele
!*******************************************     

	if (effet.eq.0) then
		do i=1,nsujet
			cpt(g(i))=cpt(g(i))+1
			
			if(nva.gt.0)then
				vet = 0.d0   
				do j=1,nva
					vet =vet + bh(np-nva+j)*dble(ve(i,j))
				end do
				vet = dexp(vet)
			else
				vet=1.d0
			endif
			
			if((c(i).eq.1).and.(stra(i).eq.1))then
				res2(g(i)) = res2(g(i))+dlog(dut1(nt1(i))*vet)
			endif  
	
			if((c(i).eq.1).and.(stra(i).eq.2))then
				res2(g(i)) = res2(g(i))+dlog(dut2(nt1(i))*vet)
			endif
	
			if(stra(i).eq.1)then
				res1(g(i)) = res1(g(i)) + ut1(nt1(i))*vet-ut1(nt0(i))*vet 
			endif
	
			if(stra(i).eq.2)then
				res1(g(i)) = res1(g(i)) + ut2(nt1(i))*vet-ut2(nt0(i))*vet 
			endif
		
		end do       
		res = 0.d0         
		cptg = 0
		
! k indice les groupes
		do k=1,ng   
			if(cpt(k).gt.0)then
				nb = nig(k)
				dnb = dble(nig(k))               
				res = res-res1(k)+res2(k) 
				cptg = cptg + 1 
			endif 
		end do
	!	if (isnan(res).or. (abs(res).gt.1.d30)) then
	!		funcpas=1.d-9
	!		goto 100
	!	end if
!*******************************************         
!----avec un effet aleatoire dans le modele
!*********************************************

	else
!      write(*,*)'AVEC EFFET ALEATOIRE'
		inv = 1.d0/theta
!     i indice les sujets
		do i=1,nsujet 
			
			cpt(g(i))=cpt(g(i))+1 
		
			if(nva.gt.0)then
				vet = 0.d0   
				do j=1,nva
					vet =vet + bh(np-nva+j)*dble(ve(i,j))
				end do
				vet = dexp(vet)
			else
				vet=1.d0
			endif
			if((c(i).eq.1).and.(stra(i).eq.1))then
				res2(g(i)) = res2(g(i))+dlog(dut1(nt1(i))*vet)
			endif  
			if((c(i).eq.1).and.(stra(i).eq.2))then
				res2(g(i)) = res2(g(i))+dlog(dut2(nt1(i))*vet)
			endif  
			if(stra(i).eq.1)then
				res1(g(i)) = res1(g(i)) + ut1(nt1(i))*vet
			endif
			
			if(stra(i).eq.2)then
				res1(g(i)) = res1(g(i)) + ut2(nt1(i))*vet
			endif
! modification pour nouvelle vraisemblance / troncature:
			if(stra(i).eq.1)then
				res3(g(i)) = res3(g(i)) + ut1(nt0(i))*vet
			endif
			
			if(stra(i).eq.2)then
				res3(g(i)) = res3(g(i)) + ut2(nt0(i))*vet
			endif
		
		end do 

		res = 0.d0
		cptg = 0
!     gam2 = gamma(inv)
! k indice les groupes
		do k=1,ng  
			sum=0.d0
			if(cpt(k).gt.0)then
				nb = nig(k)
				dnb = dble(nig(k))
				
				if (dnb.gt.1.d0) then
					do l=1,nb
						sum=sum+dlog(1.d0+theta*dble(nb-l))
					end do
				endif
				if(theta.gt.(1.d-5)) then
!ccccc ancienne vraisemblance : ANDERSEN-GILL ccccccccccccccccccccccccc
					if(AG.EQ.1)then
						res= res-(inv+dnb)*dlog(theta*(res1(k)-res3(k))+1.d0) &
						+ res2(k) + sum  
!ccccc nouvelle vraisemblance :ccccccccccccccccccccccccccccccccccccccccccccccc
					else
						res = res-(inv+dnb)*dlog(theta*res1(k)+1.d0)  &
						+(inv)*dlog(theta*res3(k)+1.d0)+ res2(k) + sum  
					endif
				else              
!     developpement de taylor d ordre 3
!                   write(*,*)'************** TAYLOR *************'
!cccc ancienne vraisemblance :ccccccccccccccccccccccccccccccccccccccccccccccc
					if(AG.EQ.1)then
						res = res-dnb*dlog(theta*(res1(k)-res3(k))+1.d0) &
						-(res1(k)-res3(k))*(1.d0-theta*(res1(k)-res3(k))/2.d0 &
						+theta*theta*(res1(k)-res3(k))*(res1(k)-res3(k))/3.d0)+res2(k)+sum

!cccc nouvelle vraisemblance :ccccccccccccccccccccccccccccccccccccccccccccccc
					else
						res = res-dnb*dlog(theta*res1(k)+1.d0)-res1(k)*(1.d0-theta*res1(k) &
						/2.d0+theta*theta*res1(k)*res1(k)/3.d0) &
						+res2(k)+sum &
						+res3(k)*(1.d0-theta*res3(k)/2.d0 &
							+theta*theta*res3(k)*res3(k)/3.d0)
					endif
				endif 
			endif 
		end do
	!	if (isnan(res).or.(abs(res).gt.1.d30)) then
		!	funcpas=1.d-9
		!	goto 100
	!	end if	

       	endif !fin boucle effet=0

!--------- calcul de la penalisation -------------------

	pe1 = 0.d0
	pe2 = 0.d0
	pe=0.d0
	do i=1,n-3
	
		pe1 = pe1+(the1(i-3)*the1(i-3)*m3m3(i))+(the1(i-2) &
		*the1(i-2)*m2m2(i))+(the1(i-1)*the1(i-1)*m1m1(i))+( &
		the1(i)*the1(i)*mmm(i))+(2.d0*the1(i-3)*the1(i-2)* &
		m3m2(i))+(2.d0*the1(i-3)*the1(i-1)*m3m1(i))+(2.d0* &
		the1(i-3)*the1(i)*m3m(i))+(2.d0*the1(i-2)*the1(i-1)* &
		m2m1(i))+(2.d0*the1(i-2)*the1(i)*m2m(i))+(2.d0*the1(i-1) &
		*the1(i)*m1m(i))
		pe2 = pe2+(the2(i-3)*the2(i-3)*m3m3(i))+(the2(i-2) &
		*the2(i-2)*m2m2(i))+(the2(i-1)*the2(i-1)*m1m1(i))+( &
		the2(i)*the2(i)*mmm(i))+(2.d0*the2(i-3)*the2(i-2)* &
		m3m2(i))+(2.d0*the2(i-3)*the2(i-1)*m3m1(i))+(2.d0* &
		the2(i-3)*the2(i)*m3m(i))+(2.d0*the2(i-2)*the2(i-1)* &
		m2m1(i))+(2.d0*the2(i-2)*the2(i)*m2m(i))+(2.d0*the2(i-1) &
		*the2(i)*m1m(i))
	
	end do
    

!    Changed JRG 25 May 05
	if (nst.eq.1) then
		pe2=0.d0
	end if

	pe = k0(1)*pe1 + k0(2)*pe2 
	
	resnonpen = res

	res = res - pe

	funcpas = res 
!100     continue
	return

	end function funcpas


!



!==========================  DISTANCE   =================================
    
   
	subroutine distances(nz1,nz2,b,effet,x1Out,lamOut,suOut,x2Out,lam2Out,su2Out)

	use tailles,only:ndatemax,npmax,NSUJETMAX
	use comon,only:date,zi,t0,t1,c,nt0,nt1,nsujet,nva,ndate, &
	nst,I_hess,H_hess,Hspl_hess,hess

	implicit none

	integer::nz1,nz2,i,j,n,np,k,l,effet
	double precision::x1,x2,h,su,bsup,binf,lam,lbinf, &
	lbsup
	double precision,dimension(npmax,npmax)::hes1,hes2
	double precision,dimension(-2:npmax)::the1,the2
	double precision,dimension(npmax)::b
	double precision,dimension(99,3)::lamOut,suOut,lam2Out,su2Out
	double precision,dimension(99)::x1Out,x2Out

  
	n  = nz1+2
	if(nst.eq.2)then      
		np  = nz1+2+nz2+2+effet+nva
	else
		np  = nz1+2+effet+nva
	endif
	  
	do i=1,nz1+2
		do j=1,nz1+2
			hes1(i,j)=hess(i,j)
		end do
	end do 

	if(nst.eq.2)then  
		k = 0
		do i=nz1+3,nz1+2+nz2+2
			k = k + 1 
			l = 0
			do j=nz1+3,nz1+2+nz2+2
				l = l + 1
				hes2(k,l)=hess(i,j)
			end do
		end do   
	endif

	do i=1,nz1+2
		the1(i-3)=(b(i))*(b(i))
	end do
	if(nst.eq.2)then  
		do i=1,nz2+2
			j = nz1+2+i
			the2(i-3)=(b(j))*(b(j))
		end do
	endif

	h = (zi(n)-zi(1))*0.01d0
	x1 = zi(1)
	x2 = zi(1)     
	
	do i=1,99 
		if(i .ne.1)then
			x1 = x1 + h 
		end if
		call cosps(x1,the1,nz1+2,hes1,zi,binf,su,bsup,lbinf,lam,lbsup)	    
		if(binf.lt.0.d0)then
		  binf = 0.d0
		endif
		if(bsup.gt.1.d0)then
		  bsup = 1.d0
		endif
		if(lbinf.lt.0.d0)then
		  lbinf = 0.d0
		endif

!   Replaced by next sentences and add new ones JRG January 05
!
!
		x1Out(i)=x1
		lamOut(i,1)=lam
		lamOut(i,2)=lbinf
		lamOut(i,3)=lbsup 
		suOut(i,1)=su
		suOut(i,2)=binf
		suOut(i,3)=bsup  


		if(nst.eq.2)then
			if(i.ne.1)then
				x2 = x2 + h 
			endif 
			call cosps(x2,the2,nz2+2,hes2,zi,binf,su,bsup,lbinf,lam,lbsup)
			if(binf.lt.0.d0)then
			  binf = 0.d0
			endif
			if(bsup.gt.1.d0)then
			  bsup = 1.d0
			endif
			if(lbinf.lt.0.d0)then
			  lbinf = 0.d0
			endif

			x2Out(i)=x2
			lam2Out(i,1)=lam
			lam2Out(i,2)=lbinf
			lam2Out(i,3)=lbsup 
			su2Out(i,1)=su
			su2Out(i,2)=binf
			su2Out(i,3)=bsup  

		endif
	end do
              
	return
	    
	end subroutine distances



!==========================  SUSP  ====================================
	subroutine susps(x,the,n,su,lam,zi)

	use tailles,only:ndatemax,npmax

	implicit none

	integer::j,k,n,i
	double precision::x,ht,ht2,h2,som,lam,su,htm,h2t,h3,h2n,hn,im,im1,im2,mm1,mm3, &
	ht3,hht,h4,h3m,hh3,hh2,mm,im3,mm2,h,gl,hh
	double precision,dimension(-2:npmax)::zi,the


	som = 0.d0
	gl = 0.d0
	
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

	end subroutine susps

!==========================  COSP  ====================================
! calcul les points pour les fonctions 
! et leur bandes de confiance

	subroutine cosps(x,the,n,y,zi,binf,su,bsup,lbinf,lam,lbsup)

	use tailles,only:ndatemax,npmax

	implicit none

	integer::j,k,n,i
	double precision::x,ht,ht2,h2,som,lam,su,binf,bsup,lbinf,lbsup,pm, &
	htm,h2t,h3,h2n,hn,im,im1,im2,mm1,mm3,ht3,hht,h4,h3m,hh3,hh2,mm,im3,mm2, &
	h,gl,hh
	double precision,dimension(-2:npmax)::the,zi
	double precision,dimension(npmax,npmax)::y


	som = 0.d0
	gl = 0.d0 

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

	call confs(x,j,n,y,pm,zi)

	binf = dexp(-gl - 1.96d0*pm)
	su  = dexp(-gl)
	bsup = dexp(-gl + 1.96d0*pm)

	call conf1s(x,j,n,y,pm,zi)
	lbinf = lam - 1.96d0*pm
	lbsup = lam + 1.96d0*pm

	return

	end subroutine cosps


!=====================  CONF1  =============================
	subroutine conf1s(x,ni,n,y,pm,zi) 

	use tailles,only:npmax,ndatemax

	implicit none

	integer::ni,i,n,j
	double precision::mmsps,x,pm,res
	double precision,dimension(-2:npmax)::zi
	double precision,dimension(npmax)::vecti,aux
	double precision,dimension(npmax,npmax)::y 
                 
	do i=1,n
	    vecti(i) = mmsps(x,ni,i,zi)
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
             
	end subroutine conf1s


!=====================  CONF  =============================
	subroutine confs(x,ni,n,y,pm,zi)

	use tailles,only:npmax,ndatemax

	implicit none

	integer::ni,i,n,j
	double precision::isps,x,pm,res
	double precision,dimension(-2:npmax)::zi
	double precision,dimension(npmax)::vecti,aux
	double precision,dimension(npmax,npmax)::y

	do i=1,n
		vecti(i) = isps(x,ni,i,zi)
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
               
	end subroutine confs


!==========================   ISP   ==================================
	double precision function isps(x,ni,ns,zi)

	use tailles,only:npmax,ndatemax

	implicit none

	integer::ni,ns
	double precision::val,mmsps,x
	double precision,dimension(-2:npmax)::zi



	if(x.eq.zi(ni))then
		if(ni.le.ns-3)then
			val = 0.d0
		else
			if(ni.le.ns-2)then
				val = ((zi(ni)-zi(ni-1))*mmsps(x,ni,ns,zi))*0.25d0
			else
				if (ni.eq.ns-1)then
					val = ((zi(ni)-zi(ni-2))*mmsps(x,ni,ns,zi)+ &
					  (zi(ni+3)-zi(ni-1))*mmsps(x,ni,ns+1,zi))*0.25d0
				else
					if(ni.eq.ns)then
						val = ((zi(ni)-zi(ni-3))*mmsps(x,ni,ns,zi)+ &
						(zi(ni+2)-zi(ni-2))*mmsps(x,ni,ns+1,zi) &
						+(zi(ni+3)-zi(ni-1))*mmsps(x,ni,ns+2,zi))*0.25d0
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
				val = (x-zi(ni))*mmsps(x,ni,ns,zi)*0.25d0
			else  
				if(ni.eq.ns-2)then
					val = ((x-zi(ni-1))*mmsps(x,ni,ns,zi)+ &
					(zi(ni+4)-zi(ni))*mmsps(x,ni,ns+1,zi))*0.25d0
				else   
					if (ni.eq.ns-1)then
						val =((x-zi(ni-2))*mmsps(x,ni,ns,zi)+ &
						(zi(ni+3)-zi(ni-1))*mmsps(x,ni,ns+1,zi) &
						+(zi(ni+4)-zi(ni))*mmsps(x,ni,ns+2,zi))*0.25d0
					else
						if(ni.eq.ns)then
							val =((x-zi(ni-3))*mmsps(x,ni,ns,zi)+ &
							(zi(ni+2)-zi(ni-2))*mmsps(x,ni,ns+1,zi) &
							+(zi(ni+3)-zi(ni-1))*mmsps(x,ni,ns+2,zi) &
							+(zi(ni+4)-zi(ni))*mmsps(x,ni,ns+3,zi))*0.25d0
						else
							val = 1.d0
						endif
					endif
				endif
			endif
		endif 
	endif

	isps = val

	return

	end function isps


!==========================  MMSP   ==================================
	double precision function mmsps(x,ni,ns,zi)

	use tailles,only:npmax,ndatemax

	implicit none

	integer::ni,ns
	double precision::val,x
	double precision,dimension(-2:npmax)::zi


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
					-zi(ni))*(zi(ni+1)-zi(ni))*(zi(ni+2)-zi(ni-1)))  &
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
						+((4.d0*((x-zi(ni-1))*(zi(ni+2)-x) & 
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

	mmsps = val

	return

	end function mmsps



!========================          MNBRAK         ===================
	subroutine mnbraks(ax,bx,cx,fa,fb,fc,b,n)

	use tailles,only:npmax

	implicit none

	double precision::ax,bx,cx,fa,fb,fc,aux,res
	double precision,dimension(npmax)::b
	double precision,dimension(npmax,npmax)::y
	double precision::estimvs,gold,glimit,tiny
	parameter (gold=1.618034d0,glimit=100.d0,tiny=1.d-20)
	double precision::dum,fu,q,r,u,ulim
	integer::n,ni

	fa = estimvs(ax,n,b,y,aux,ni,res)
	fb = estimvs(bx,n,b,y,aux,ni,res)

	if(fb.gt.fa)then
		dum = ax
		ax = bx
		bx = dum
		dum = fb
		fb = fa
		fa = dum
	endif

	cx = bx + gold*(bx-ax)
	fc = estimvs(cx,n,b,y,aux,ni,res)

 1       if(fb.ge.fc)then
		r = (bx-ax)*(fb-fc)
		q = (bx-cx)*(fb-fa)
		u = bx-((bx-cx)*q-(bx-ax)*r)/(2.d0*sign(max(abs(q-r),tiny),q-r))
		ulim = bx + glimit*(cx-bx)

		if((bx-u)*(u-cx).gt.0.d0)then
			fu = estimvs(u,n,b,y,aux,ni,res)
			if(fu.lt.fc)then
				ax = bx
				fa = fb
				bx = u
				fb = fu
				return
			else
				if(fu.gt.fb)then
					cx = u
					fc = fu
					return
				endif   
			endif
			u = cx + gold*(cx-bx)
			fu = estimvs(u,n,b,y,aux,ni,res)
		else
			if((cx-u)*(u-ulim).gt.0.d0)then
				fu = estimvs(u,n,b,y,aux,ni,res)
				if(fu.lt.fc)then
					bx = cx
					cx = u
					u = cx + gold*(cx-bx)
					fb = fc
					fc = fu
					fu = estimvs(u,n,b,y,aux,ni,res)
				endif  
			else
				if((u-ulim)*(ulim-cx).ge.0.d0)then
					u = ulim
					fu = estimvs(u,n,b,y,aux,ni,res)
				else
					u = cx + gold*(cx-bx)
					fu = estimvs(u,n,b,y,aux,ni,res)
				endif
			endif   
		endif
		ax = bx
		bx = cx
		cx = u
		fa = fb
		fb = fc
		fc = fu
		goto 1
	endif

	return 

	end subroutine mnbraks

!========================      GOLDEN   =========================
	double precision function goldens(ax,bx,cx,tol,xmin,n,b,y,aux)

	use tailles,only:npmax,ndatemax

	implicit none
	
	double precision,dimension(npmax,npmax)::y
	double precision,dimension(npmax)::b
	double precision::ax,bx,cx,tol,xmin,r,c,aux,res
	parameter (r=0.61803399d0,c=1.d0-r)
	double precision::f1,f2,x0,x1,x2,x3,estimvs
	integer::n,ni
      
	x0 = ax
	x3 = cx
	if(abs(cx-bx).gt.abs(bx-ax))then
		x1 = bx
		x2 = bx + c*(cx-bx)
	else
		x2 = bx
		x1 = bx - c*(bx-ax)
         endif

         f1 = estimvs(x1,n,b,y,aux,ni,res)
         f2 = estimvs(x2,n,b,y,aux,ni,res)
         
 1       if(abs(x3-x0).gt.tol*(abs(x1)+abs(x2)))then
		if(f2.lt.f1)then
			x0 = x1
			x1 = x2
			x2 = r*x1 + c*x3
			f1 = f2
			f2 = estimvs(x2,n,b,y,aux,ni,res)
		else
			x3 = x2
			x2 = x1
			x1 = r*x2+c*x0
			f2 = f1
			f1 = estimvs(x1,n,b,y,aux,ni,res)
		endif
		go to 1
	endif
	if(f1.lt.f2)then
		goldens = f1
		xmin = x1
	else
		goldens = f2
		xmin = x2
	endif

	return

	end function goldens


!========================          ESTIMV         ===================

	double precision function estimvs(k00,n,b,y,aux,ni,res)

	use tailles,only:npmax,ndatemax,NSUJETMAX
	use comon,only:t0,t1,c,nt0,nt1,nsujet,nva,ndate,nst, &
	date,zi,pe,effet,nz1,nz2,mm3,mm2,mm1,mm,im3,im2,im1,im

	use optim
	implicit none

	double precision,dimension(npmax,npmax)::y
	double precision,dimension((npmax*(npmax+3)/2))::v
	double precision,dimension(-2:npmax)::the
	double precision,dimension(2)::k0
	double precision,dimension(ndatemax)::ut,dut
	double precision,dimension(npmax)::bh,b
	double precision::res,k00,som,h1
	double precision::aux
	integer::n,ij,i,k,j,vj,ier,istop,ni
	double precision::ca,cb,dd,funcpas
	external::funcpas
      
	j=0
	estimvs=0.d0

	k0(1) = k00*k00
	k0(2) = 0.d0

	call marq98j(k0,b,n,ni,v,res,ier,istop,effet,ca,cb,dd,funcpas)
!AD:	
!	if (istop.eq.4) goto 50
!AD:	
	
	if(k0(1).gt.0.d0)then
		do ij=1,n
			the(ij-3)=(b(ij))*(b(ij))
			bh(ij) = (b(ij))*(b(ij))
		end do
         
		vj = 0
		som = 0.d0
		dut(1) = (the(-2)*4.d0/(zi(2)-zi(1)))
		ut(1) = the(-2)*dut(1)*0.25d0*(zi(1)-zi(-2))
		do i=2,ndate-1
			do k = 2,n-2
				if ((date(i).ge.zi(k-1)).and.(date(i).lt.zi(k)))then
					j = k-1
					if ((j.gt.1).and.(j.gt.vj))then
						som = som+the(j-4)
						vj  = j
					endif   
				endif
			end do 
			ut(i) = som +(the(j-3)*im3(i))+(the(j-2)*im2(i)) &
			    +(the(j-1)*im1(i))+(the(j)*im(i))
			dut(i) = (the(j-3)*mm3(i))+(the(j-2)*mm2(i)) &
			    +(the(j-1)*mm1(i))+(the(j)*mm(i))
		end do
		i = n-2
		h1 = (zi(i)-zi(i-1))
		ut(ndate) = som+ the(i-4) + the(i-3)+the(i-2)+the(i-1)
		dut(ndate) = (4.d0*the(i-1)/h1)
		
		call tests(dut,k0,n,aux,y)
		estimvs = - ((res-pe)) - aux

	else
		aux = -n
	endif
!AD:
!50	continue      
!AD:
	return

	end function estimvs
      
!=================calcul de la hessienne  et de omega  ==============
	subroutine tests(dut,k0,n,res,y)

	use tailles,only:npmax,ndatemax,NSUJETMAX
	use comon,only:date,zi,t0,t1,c,nt0,nt1,nsujet,nva,ndate, &
	nst


	implicit none

	double precision,dimension(npmax,npmax)::hessh,hess,omeg,y
	integer,dimension(npmax)::indx
	integer::n,i,j,np
	double precision,dimension(2)::k0
	double precision,dimension(ndatemax)::dut
	double precision::d,res,tra


	do i = 1,n
		do j = 1,n
			hess(i,j) = 0.d0 
		end do
	end do
   
 
	do i = 1,n
		do j = i,n
			call mats(hess(i,j),dut,i,j,n)
		end do
	end do
	do i = 2,n
		do j = 1,i-1
			hess(i,j)=hess(j,i)
		end do
	end do


	call calcomegs(n,omeg)

	do i = 1,n
		do j = 1,n
			hessh(i,j)=-hess(i,j)
			hess(i,j) = hess(i,j) - (2.d0*k0(1)*omeg(i,j)) 
		end do   
	end do

	np = n
	do i=1,n
		do j=1,n
			y(i,j)=0.d0
		end do
		y(i,i)=1.d0
	end do

	call ludcmps(hess,n,indx,d)

	do j=1,n
		call lubksbs(hess,n,indx,y(1,j))
	end do

	tra = 0.d0
	do i=1,n
		do j=1,n
			tra = tra + y(i,j)*hessh(j,i)
		end do
	end do

	res = (tra)

	end subroutine tests


!=======================  CALOMEG  ===========================
	subroutine calcomegs(n,omeg)

	use tailles,only:npmax,ndatemax
	use comon,only:date,zi,m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m
	  
	implicit none

	double precision,dimension(npmax,npmax)::omeg
	integer::n,i,j
	double precision::calc00s,calc01s,calc02s

	do i=1,n
		do j=1,n
			omeg(i,j)=0.d0
		end do
	end do
      
	omeg(1,1)=calc00s(1,n)
	omeg(1,2)=calc01s(1,n)
	omeg(1,3)=calc02s(1,n)
	omeg(1,4)=m3m(1)
	omeg(2,1)=omeg(1,2)
	omeg(2,2)=calc00s(2,n)
	omeg(2,3)=calc01s(2,n)
	omeg(2,4)=calc02s(2,n)
	omeg(2,5)=m3m(2)
	omeg(3,1)=omeg(1,3)
	omeg(3,2)=omeg(2,3)
	omeg(3,3)=calc00s(3,n)
	omeg(3,4)=calc01s(3,n)
	omeg(3,5)=calc02s(3,n)
	omeg(3,6)=m3m(3)

	do i=4,n-3
		omeg(i,i-3)=omeg(i-3,i)
		omeg(i,i-2)=omeg(i-2,i)
		omeg(i,i-1)=omeg(i-1,i)
		omeg(i,i)=calc00s(i,n)
		omeg(i,i+1)=calc01s(i,n)
		omeg(i,i+2)=calc02s(i,n)
		omeg(i,i+3)=m3m(i)
	end do  
 
	omeg(n-2,n-5)=omeg(n-5,n-2)
	omeg(n-2,n-4)=omeg(n-4,n-2)
	omeg(n-2,n-3)=omeg(n-3,n-2)
	omeg(n-2,n-2)=calc00s(n-2,n)
	omeg(n-2,n-1)=calc01s(n-2,n)
	omeg(n-2,n)=calc02s(n-2,n)
	omeg(n-1,n-4)=omeg(n-4,n-1)
	omeg(n-1,n-3)=omeg(n-3,n-1)
	omeg(n-1,n-2)=omeg(n-2,n-1)
	omeg(n-1,n-1)=calc00s(n-1,n)
	omeg(n-1,n)=calc01s(n-1,n)
	omeg(n,n-3)=omeg(n-3,n)
	omeg(n,n-2)=omeg(n-2,n)
	omeg(n,n-1)=omeg(n-1,n)
	omeg(n,n)=calc00s(n,n)

	end subroutine calcomegs


!====================  MAT  ==================================
	subroutine mats(res,dut,k,l,n)

	use tailles,only:npmax,ndatemax,NSUJETMAX
	use comon,only:date,zi,t0,t1,c,nt0,nt1,nsujet,nva,ndate, &
	nst


	implicit none

	double precision::res,res1,msps,aux2,u2
	double precision,dimension(ndatemax)::dut
	integer::k,l,j,ni,n,i
          
!--------- calcul de la hessienne ij ------------------
	res = 0.d0
	res1 = 0.d0
	do i=1,nsujet
		if(c(i).eq.1)then  !event
			u2 = dut(nt1(i)) 
			do j = 2,n-2
				if((date(nt1(i)).ge.zi(j-1)).and. &
					(date(nt1(i)).lt.zi(j)))then
					ni = j-1
				endif
			end do 
			if(date(nt1(i)).eq.zi(n-2))then
				ni = n-2
			endif   
!------attention numero spline 
			aux2 = msps(nt1(i),ni,k)*msps(nt1(i),ni,l)
			if (u2.le.0.d0)then
				res1 = 0.d0
			else   
				res1 = - aux2/(u2*u2)
			endif  
		else !censure  
			res1 = 0.d0
		endif 
		res = res + res1
	end do   
       
	end subroutine mats

!==========================  MSP   ==================================
	double precision function msps(i,ni,ns)

	use tailles,only:npmax,ndatemax   
	use comon,only:date,zi

	implicit none

	integer::ni,ns,i
	double precision::val

	if(ni.lt.ns-3)then
		val = 0.d0
	else
		if(ns-3.eq.ni)then
			if(date(i).eq.zi(ni))then
				val = 0.d0
			else  
				val = (4.d0*(date(i)-zi(ni))*(date(i)-zi(ni)) &
				*(date(i)-zi(ni)))/((zi(ni+4)-zi(ni))*(zi(ni+3) &
				-zi(ni))*(zi(ni+2)-zi(ni))*(zi(ni+1)-zi(ni)))
			endif
		else 
			if(ns-2.eq.ni)then
				if(date(i).eq.zi(ni))then
					val = (4.d0*(zi(ni)-zi(ni-1))*(zi(ni)-zi(ni-1))) &
					/((zi(ni+3)-zi(ni-1))*(zi(ni+2)-zi(ni-1)) &
					*(zi(ni+1)-zi(ni-1)))
				else  
					val = (4.d0*(date(i)-zi(ni-1))*(date(i)-zi(ni-1)) &
					*(zi(ni+1)-date(i)))/((zi(ni+3)-zi(ni-1))*(zi(ni+2) &
					-zi(ni-1))*(zi(ni+1)-zi(ni-1))*(zi(ni+1)-zi(ni))) &
					+   (4.d0*(date(i)-zi(ni-1))*(date(i)-zi(ni)) &
					*(zi(ni+2)-date(i)))/((zi(ni+3)-zi(ni-1))*(zi(ni+2) &
					-zi(ni))*(zi(ni+1)-zi(ni))*(zi(ni+2)-zi(ni-1))) &
					+   (4.d0*(date(i)-zi(ni))*(date(i)-zi(ni)) &
					*(zi(ni+3)-date(i)))/((zi(ni+3)-zi(ni-1))*(zi(ni+3) &
					-zi(ni))*(zi(ni+2)-zi(ni))*(zi(ni+1)-zi(ni)))
				endif
			else   
				if (ns-1.eq.ni)then
					if(date(i).eq.zi(ni))then
						val = (4.d0*((zi(ni)-zi(ni-2))*(zi(ni+1) &
						-zi(ni)))/((zi(ni+2)-zi(ni-2))*(zi(ni+1) &
						-zi(ni-1))*(zi(ni+1)-zi(ni-2)))) &
						+((4.d0*((zi(ni)-zi(ni-1))*(zi(ni+2)-zi(ni)))  &
						/((zi(ni+2)-zi(ni-2))*(zi(ni+2)-zi(ni-1)) &
						*(zi(ni+1)-zi(ni-1)))))
					else
						val = (4.d0*((date(i)-zi(ni-2))*(zi(ni+1) &
						-date(i))*(zi(ni+1)-date(i)))/((zi(ni+2) &
						-zi(ni-2))*(zi(ni+1)-zi(ni-1))*(zi(ni+1)- &
						zi(ni))*(zi(ni+1)-zi(ni-2)))) &
						+((4.d0*((date(i)-zi(ni-1))*(zi(ni+2)-date(i)) & 
						*(zi(ni+1)-date(i)))/((zi(ni+2)-zi(ni-2)) &
						*(zi(ni+2)-zi(ni-1))*(zi(ni+1)-zi(ni-1))* &
						(zi(ni+1)-zi(ni))))) &
						+((4.d0*((zi(ni+2)-date(i))*(zi(ni+2)-date(i)) & 
						*(date(i)-zi(ni)))/((zi(ni+2)-zi(ni-2)) &
						*(zi(ni+2)-zi(ni))*(zi(ni+2)-zi(ni-1))* &
						(zi(ni+1)-zi(ni)))))
					endif 
				else
					if(ni.eq.ns)then
						if(date(i).eq.zi(ni))then
							val =(4.d0*(date(i)-zi(ni+1))*(date(i) &
							-zi(ni+1))/((zi(ni+1)-zi(ni-1))*(zi(ni+1) &
							-zi(ni-2))*(zi(ni+1)-zi(ni-3))))
						else   
							val =(4.d0*(date(i)-zi(ni+1))*(date(i) &
							-zi(ni+1))*(zi(ni+1)-date(i))/((zi(ni+1) &
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

	msps = val

	return

	end function msps


!=========================  CALC00  =========================
	double precision function calc00s(j,n) 

	use tailles,only:npmax
	use comon,only:m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m

	implicit none

	double precision::part
	integer::j,n

	if(j.eq.1)then
		part = m3m3(j)
	else
		if(j.eq.2)then
			part = m3m3(j) + m2m2(j-1)
		else
			if(j.eq.3)then
				part = m3m3(j) + m2m2(j-1) + m1m1(j-2)
			else
				if(j.eq.n-2)then
					part = m2m2(j-1) + m1m1(j-2) + mmm(j-3)
				else   
					if(j.eq.n-1)then
						part = mmm(j-3) + m1m1(j-2)
					else
						if(j.eq.n)then
							part = mmm(j-3)
						else   
							part=mmm(j-3)+m1m1(j-2)+m2m2(j-1)+m3m3(j)
						endif
					endif
				endif   
			endif   
                endif   
	endif 

	calc00s = part

	return

	end function calc00s


!=========================  CALC01  =========================
	double precision function calc01s(j,n)

	use tailles,only:npmax
	use comon,only:m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m

	implicit none

	double precision::part
	integer::j,n

	if(j.eq.1)then
		part = m3m2(j)
	else   
		if(j.eq.2)then
			part = m3m2(j) + m2m1(j-1) 
		else
			if(j.eq.n-2)then
				part = m1m(j-2) + m2m1(j-1) 
			else
				if(j.ne.n-1)then
					part = m3m2(j) + m2m1(j-1) + m1m(j-2)
				else
					part = m1m(j-2)
				endif
			endif   
		endif
	endif   

	calc01s = part

	return

	end function calc01s
!=========================  CALC02  =========================
	double precision function calc02s(j,n)

	use tailles,only:npmax	
	use comon,only:m3m3,m2m2,m1m1,mmm,m3m2,m3m1,m3m,m2m1,m2m,m1m

	implicit none

	double precision::part
	integer::j,n

	if(j.eq.1)then
		part = m3m1(j)
	else   
		if(j.ne.n-2)then
			part = m3m1(j) + m2m(j-1) 
		else
			part = m2m(j-1)
		endif
	endif   

	calc02s = part

	return

	end function calc02s


!================== multiplication de matrice  ==================
	
	! multiplie A par B avec le resultat dans C
	
	subroutine multis(A,B,IrowA,JcolA,JcolB,C)
	
	use tailles,only:npmax
	
	implicit none
	
	integer::IrowA,JcolA,JcolB,i,j,k
	double precision::sum
	double precision,dimension(npmax,npmax) ::A,B,C
	
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
	
	end subroutine multis
			     
	

!======================  LUBKSB  ======================================
	subroutine lubksbs(a,n,indx,b)
	
	use tailles,only:npmax
	
	implicit none

	integer::n,i,ii,j,ll
	integer,dimension(npmax)::indx
	double precision,dimension(npmax,npmax)::a
	double precision,dimension(npmax)::b
	double precision::sum

	ii = 0
	do i=1,n
		ll = indx(i)
		sum = b(ll)
		b(ll) = b(i)
		if(ii.ne.0)then
			do j=ii,i-1
				sum = sum -a(i,j)*b(j)
			end do
		else
			if(sum.ne.0.d0)then
				ii=i
			endif
		endif
		b(i)=sum
	end do
	
	do i=n,1,-1
		sum = b(i)
		do j = i+1,n
			sum = sum-a(i,j)*b(j)
		end do
		b(i)=sum/a(i,i)
	end do
       
	return

	end subroutine lubksbs	
	
!======================  LUDCMP  ======================================
       subroutine ludcmps(a,n,indx,d)
    	
	use tailles,only:npmax
	
	implicit none
	
	integer::n,i,imax,j,k
	integer,dimension(n)::indx
	double precision::d
	double precision,dimension(npmax,npmax)::a
	integer,parameter::nmax=500
	double precision,parameter::tiny=1.d-20
	double precision aamax,dum,sum
	double precision,dimension(nmax)::vv
	
	imax=0
	d = 1.d0
	do i=1,n
		aamax=0.d0
		do j=1,n
			if (dabs(a(i,j)).gt.aamax)then
				aamax=dabs(a(i,j))
			endif
		end do
		vv(i) = 1.d0/aamax
	end do
	
	do j = 1,n
		do i=1,j-1
			sum = a(i,j)
			do k=1,i-1
				sum = sum - a(i,k)*a(k,j)
			end do
			a(i,j) = sum
		end do
		aamax = 0.d0
		do i = j,n
			sum = a(i,j)
			do k=1,j-1
				sum = sum -a(i,k)*a(k,j)
			end do
			a(i,j) = sum
			dum = vv(i)*dabs(sum)
			if (dum.ge.aamax) then
				imax = i
				aamax = dum
			endif
		end do
		if(j.ne.imax)then
			do k=1,n
				dum = a(imax,k)
				a(imax,k)=a(j,k)
				a(j,k) = dum
			end do
			d = -d
			vv(imax)=vv(j)
		endif
		
		indx(j)=imax
		if(a(j,j).eq.0.d0)then
			a(j,j)=tiny
		endif
		
		if(j.ne.n)then
			dum = 1.d0/a(j,j)
			do i = j+1,n
				a(i,j) = a(i,j)*dum
			end do
		endif
	end do
 
	return
	
	end subroutine ludcmps
!==================================================================
!AD: IS NAN

!	logical function isnan(x)
!
!	implicit none
!	
!	double precision,intent(in)::x
!	
!	if (x .ne. x) then
!		isnan=.true.
!	else
!		isnan=.false.
!	end if
!
!	end function isnan


!AD:end
!====================================================================
	
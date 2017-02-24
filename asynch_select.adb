with Ada.Text_IO;

-- This will demonstrate that asynchronous select statements should
-- not be used as a dual-entry select statement, since both entries
-- may be executed.
-- 
-- August 2012, Egil H. Høvik
-- 
procedure Asynch_Select is

   protected type Protected_Foo is
      procedure Open_Barrier;   
      entry Set;
      function Get return Boolean;
   private
      Is_Called : Boolean := False;
      Barrier : Boolean := False;
   end Protected_Foo;
   
   
   protected body Protected_Foo is
   
      procedure Open_Barrier is
      begin
         Barrier := True;
      end Open_Barrier;
      
      entry Set when Barrier is
      begin
         Is_Called := True;
      end Set;
      
      function Get return Boolean
      is
      begin
         return Is_Called;
      end Get;
      
   end Protected_Foo;


   protected type Protected_Bar is
      entry Set;
      function Get return Boolean;
   private
      Is_Called : Boolean := False;
   end Protected_Bar;
   
   
   protected body Protected_Bar is
   
      entry Set when True is
      begin
         Is_Called := True;

         -- force a task switch here to demonstrate how an
         -- unfortunate task switch inside this entry can cause
         -- confusing semantics. (delay statement will give
         -- warning about a potentially blocking operation inside
         -- protected object. A busy loop can be used instead to
         -- demonstrate the effect, but can be impractical to get
         -- the timing correct, especially on single-core machines)         
         delay 1.0; 
      end Set;
      
      function Get return Boolean
      is
      begin
         return Is_Called;
      end Get;
      
   end Protected_Bar;
   
   
   Foo : Protected_Foo;
   Bar : Protected_Bar;
   
   
   task Foo_Opener;
   
   task body Foo_Opener is
   begin
      delay 0.5;
      
      -- this will open the barrier of Foo.Set during 
      -- execution of Bar.Set. A task switch during
      -- Bar.Set will then cause Foo.Set to execute 
      -- (and complete) before Bar.Set is complete.
      Foo.Open_Barrier; 
   end Foo_Opener;
   
begin

   select
      Foo.Set;
   then abort
      Bar.Set;
   end select;

   Ada.Text_IO.Put_Line("Foo called => " & Boolean'Image(Foo.Get));
   Ada.Text_IO.Put_Line("Bar called => " & Boolean'Image(Bar.Get));
   
end Asynch_Select;

# WorkManager creates this Room-generated database implementation reflectively.
# AGP 9 strict R8 keep-rule handling does not retain its no-argument constructor
# from the older Room consumer rule alone.
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}

//=====================================================================
//
//  File:      ascmd.cs
//  Summary:   A command-line utility to execute Analysis Services XMLA scripts
//             or MDX queries
//  Authors:   Dave Wickert (dwickert@microsoft.com)
//  Date:	   03-Jan-2006
//
//  Change history:
//    -Jul-2007: EricJ    : Added input parsing from xml format.
//                          Added -oResultStat for output result statistics.
//                          Added RandomSeed, ThinkTimeMin, ThinkTimeMax, ConnectWaitMin, ConnectWaitMax.
//  07-Apr-2008: dwickert : Added scripting variable support for RandomSeed, ThinkTimeMin, 
//                          ThinkTimeMax, ConnectWaitMin, ConnectWaitMax.
//  10-Apr-2008: dwickert : Added -Xf (exit file) option with matching scripting variable support
//  18-Aug-2008: dwickert : integrated and prep'ed for 2008 support
//  20-Aug-2008: dwickert : Released SQL 2008 beta1
//  27-Aug-2008: dwickert : Fixed bug in -U logon processing (was disposing of token handle early)
//  28-Aug-2008: dwickert : Finalized support SQL 2008 (+ various naming issues that fxcop found)
//  02-Sep-2008: dwickert : Fixed bug with input file name as query name when multiple input files used

// @TODO: (1) add InputPatternBegin, InputPatternEnd
// @TODO: (2) add support for "go;" with semicolon
// @TODO: (3) Consider moving ResultStat to separate utility
// @TODO: (4) Why does it not measure query duration?
// @TODO: (5) Add tag to output to csv file verbatim info, to help create output for excel
//
//---------------------------------------------------------------------
//
//  This file is part of the Microsoft SQL Server Code Samples.
//  Copyright (C) Microsoft Corporation.  All rights reserved.
//
//This source code is intended only as a supplement to Microsoft
//Development Tools and/or on-line documentation.  See these other
//materials for detailed information regarding Microsoft code samples.
//
//THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
//ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
//THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
//PARTICULAR PURPOSE.
//
//===================================================================== 

// Note: the code below contains additional lines to check for strong
// naming convention of obects, e.g. server names, usernames, passwords, etc.
// However, since we don't know what you guidelines will be we were not
// able to assume your specific values. Free from to change ParseArgs and add
// minimum, maximum and invalid object characters based on your 
// individual naming conventions.

// Line length (limit to 79 characters for formatting)
//       1         2         3         4         5         6         7
//34567890123456789012345678901234567890123456789012345678901234567890123456789

using System;
using System.Web;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using System.Globalization;
using System.Threading;
using Microsoft.Samples.SqlServer.Properties; // the locSting resources

using Microsoft.AnalysisServices;             //AMO
using Microsoft.AnalysisServices.AdomdClient; //ADOMD.NET

// needed for Logon Win32 API call and user impersonation //
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Security.Permissions;

// needed for random number generation
using Microsoft.Samples.SqlServer.ASCmd.RandomHelper;

[assembly: CLSCompliant(true)]
namespace Microsoft.Samples.SqlServer.ASCmd
{
    internal static class NativeMethods
    {
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool LogonUser(String lpszUsername, String lpszDomain, String lpszPassw_outord,
            int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr handle);
    }

    class CmdMain
    {

        #region Assembly Attribute Accessors

        //static string AssemblyTitle // not used yet
        //{
        //    get
        //    {
        //        // Get all Title attributes on this assembly
        //        object[] attributes = System.Reflection.Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyTitleAttribute), false);
        //        // If there is at least one Title attribute
        //        if (attributes.Length > 0)
        //        {
        //            // Select the first one
        //            AssemblyTitleAttribute titleAttribute = (AssemblyTitleAttribute)attributes[0];
        //            // If it is not an empty string, return it
        //            if (titleAttribute.Title != "")
        //                return titleAttribute.Title;
        //        }
        //        // If there was no Title attribute, or if the Title attribute was the empty string, return the .exe name
        //        return System.IO.Path.GetFileNameWithoutExtension(System.Reflection.Assembly.GetExecutingAssembly().CodeBase);
        //    }
        //}

        static string AssemblyVersion
        {
            get
            {
                return System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();
            }
        }

        static string AssemblyDescription
        {
            get
            {
                // Get all Description attributes on this assembly
                object[] attributes = System.Reflection.Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyDescriptionAttribute), false);
                // If there aren't any Description attributes, return an empty string
                if (attributes.Length == 0)
                    return "";
                // If there is a Description attribute, return its value
                return ((AssemblyDescriptionAttribute)attributes[0]).Description;
            }
        }

        static string AssemblyProduct // not used yet
        {
            get
            {
                // Get all Product attributes on this assembly
                object[] attributes = System.Reflection.Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyProductAttribute), false);
                // If there aren't any Product attributes, return an empty string
                if (attributes.Length == 0)
                    return "";
                // If there is a Product attribute, return its value
                return ((AssemblyProductAttribute)attributes[0]).Product;
            }
        }

        static string AssemblyCopyright
        {
            get
            {
                // Get all Copyright attributes on this assembly
                object[] attributes = System.Reflection.Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyCopyrightAttribute), false);
                // If there aren't any Copyright attributes, return an empty string
                if (attributes.Length == 0)
                    return "";
                // If there is a Copyright attribute, return its value
                return ((AssemblyCopyrightAttribute)attributes[0]).Copyright;
            }
        }

        //static string AssemblyCompany // not used yet
        //{
        //    get
        //    {
        //        // Get all Company attributes on this assembly
        //        object[] attributes = System.Reflection.Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyCompanyAttribute), false);
        //        // If there aren't any Company attributes, return an empty string
        //        if (attributes.Length == 0)
        //            return "";
        //        // If there is a Company attribute, return its value
        //        return ((AssemblyCompanyAttribute)attributes[0]).Company;
        //    }
        //}

        static string AssemblyProcessorArchitecture
        {
            get
            {
                return System.Reflection.Assembly.GetExecutingAssembly().GetName().ProcessorArchitecture.ToString();
            }
        }

        #endregion

        #region Class Variables

        // message handling for loc strings
        static string Msg(string locString) { return (AssemblyProduct + ": " + locString); }

        // What options have been seen on the command line
        static bool Option_U_specified;
        static bool Option_P_specified;
        static bool Option_S_specified;
        static bool Option_d_specified;
        static bool Option_t_specified;
        static bool Option_tc_specified;
        static bool Option_i_specified;
        static bool Option_o_specified;
        static bool Option_oResultStat_specified;
        static bool Option_NoResultStatHeader_specified;
        static bool Option_RunInfo_specified;
        static bool Option_RandomSeed_specified;
        static bool Option_ThinkTimeMin_specified;
        static bool Option_ThinkTimeMax_specified;
        static bool Option_ConnectWaitMin_specified;
        static bool Option_ConnectWaitMax_specified;
        static bool Option_T_specified;
        static bool Option_Tt_specifed;
        static bool Option_Tf_specified;
        static bool Option_Tl_specified;
        static bool Option_Td_specified;
        static bool Option_Q_specified;
        static bool Option_xc_specified;
        static bool Option_v_specified;
        static bool Option_Xf_specified;

        // Variables for options
        static string UserName = "";
        static string Domain = "";
        static string Password = "";
        static string Server = "localhost";
        static string Instance = "";
        static string Database = "";
        static string InputFile = "";
        static string OutputFile = "";
        static string OutputResultStatFile = "";
        static string RunInfo = "";
        static string TraceFile = "";
        static string Query = "";
        static string ExtendedConnectstring = "";
        static string TraceFormat = "csv"; // use the -f option
        static string Timeout = "";
        static string ConnectTimeout = "";
        static string TraceTimeout = "5"; // trace is finished if no activity for 5 seconds
        static bool httpConnection;
        static int RandomSeed;
        static int ThinkTimeMin;
        static int ThinkTimeMax;
        static int ConnectWaitMin;
        static int ConnectWaitMax;
        static string ExitFile = ""; // exit file (if specified)

        // provider to use -- should we have this an an option (i.e. -p) ??
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        const string Provider = "MSOLAP.3"; // force AS2K5 provider

        // Variables for read/writing
        static StringBuilder sb = new StringBuilder(); // input stream
        static StreamWriter sw_out; //Output file
        static StreamWriter sw_outResultStat; //Output file
        static bool IsOutputFileOpen;
        static bool IsOutputResultStatFileOpen;
        static StreamWriter sw_trace; //Trace file
        static bool IsTraceFileOpen;
        static string TraceDelim = "|";
        static string TraceLevel = "high"; // default is to trace at the high level
        static long BeginEndBlockCount; // if 0 then OK to immediately finish trace
        static int TraceTimeoutCount; // if goes to 0, then finish trace regardless of BeginEndBlockCount
        static int TraceTimeoutCountReset; // the amount of time to wait once trace events stop
        static bool TraceStarted; // have the trace events started to flow?
        const int PollingInterval = 20; // Every 1/20th of a second (50ms) see if trace is done (BeginEndBlockCount drives to 0)
        static bool ExceptionSeen; // have we seen an exception in the xmla return stream

        static bool _DEBUGMODE; // Set to indicate that we need debug messages outputted

        static HighPerformanceRandom perfRandom;

        // substitution table -- includes -v entries plus command-line arguments
        static Dictionary<string, string> substituteWith =
            new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase);

        // maximum timeout values (if used)
        const int maxTimeout = -1; // -1 means don't check

        // regular expressions used
        const string ScriptingVarRefRegex = @"\$\([a-zA-Z0-9_-]+\)";
        const string ScriptingVarNameRegex = @"^[a-zA-Z0-9_-]+=.*";
        const string XMLACommandRegex =
                        @"(?sx)^(<Alter.*|
                                 <Attach.*|
                                 <Backup.*|
                                 <Batch.*|
                                 <BeginTransaction.*|
                                 <Cancel.*|
                                 <ClearCache.*|
                                 <CommitTransaction.*|
                                 <Create.*|
                                 <Delete.*|
                                 <DesignAggregations.*|
                                 <Detach.*|
                                 <Drop.*|
                                 <Insert.*|
                                 <Lock.*|
                                 <MergePartitions.*|
                                 <NotifyTableChange.*|
                                 <Process.*|
                                 <Restore.*|
                                 <RollbackTransaction.*|
                                 <SetPasswordEncryptionKey.*|
                                 <Statement.*|
                                 <Subscribe.*|
                                 <Synchronize.*|
                                 <Unlock.*|
                                 <Update.*|
                                 <UpdateCells.*)$";
        const string DiscoverRegex = @"(?sx)^<Discover.*$";
        const string ExecuteRegex = @"(?sx)^<Execute.*$";
        const string BatchRegex = @"^[\w\W]*?[\r\n]*go\s";
        const string InputFileFormat = "**InputFile: {0}\n";
        const string InputFileRegex = @"(?sx)^\*\*InputFile: (?<inputFile>[\w\W]+?)\n(?<batchText>.*)$";

        // formats
        const string SoapEnvFormat =
            @"<Envelope xmlns='http://schemas.xmlsoap.org/soap/envelope/'>
                <Body>
                {0}
                </Body>
              </Envelope>";

        #endregion

        // --------------------------------------------------------------------
        // Main routine -- called with the command line arguments
        [SecurityPermission(SecurityAction.Assert, Flags = SecurityPermissionFlag.UnmanagedCode)]
        static int Main(string[] args)
        {
            //HighPerformanceRandom.TestShowWithSeeds();
            //HighPerformanceRandom.Test2();
            try
            {
                Console.WriteLine(AssemblyDescription);
                Console.WriteLine(Properties.Resources.locVersion,
                            AssemblyVersion, AssemblyProcessorArchitecture);
                Console.WriteLine(AssemblyCopyright);

                // Parse the command line argument list, verify the options and
                // open any requested files
                try
                {
                    if (!ParseArgs(args))
                    {
                        return 1; // if it returns an error, just exit
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine(Msg(Properties.Resources.locParseArgsErr),
                                ex.Message);
                    return 1; // error raised
                }

                // Take the input stream and substitute any scripting variables within it
                SubstituteScriptingVariables(sb);

                // Impersonate the -U username (if needed) and then **execute** the
                // query or script. Note: http connections set the UID and PWD in
                // the connect string
                if ((UserName.Length > 0) && !httpConnection)
                {
                    try
                    {
                        // Need to impersonate the user first -- then ex

                        const int LOGON32_PROVIDER_DEFAULT = 0;
                        //This parameter causes LogonUser to create a primary token.
                        const int LOGON32_LOGON_INTERACTIVE = 2;

                        IntPtr tokenHandle = new IntPtr(0);
                        tokenHandle = IntPtr.Zero;

                        // Call LogonUser to obtain a handle to an access token.
                        if (_DEBUGMODE) Console.WriteLine("Calling LogonUser");
                        bool returnValue = NativeMethods.LogonUser(UserName, Domain, Password,
                            LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT,
                            ref tokenHandle);

                        if (false == returnValue)
                        {
                            int ret = Marshal.GetLastWin32Error();
                            Console.WriteLine(Msg(Properties.Resources.locLogonFailedErr), ret);
                            throw new System.ComponentModel.Win32Exception(ret);
                        }

                        if (_DEBUGMODE) Console.WriteLine("Did LogonUser Succeed? " + (returnValue ? "Yes" : "No"));
                        if (_DEBUGMODE) Console.WriteLine("Value of Windows NT token: " + tokenHandle);

                        // Check the identity.
                        if (_DEBUGMODE) Console.WriteLine("Before impersonation: " + WindowsIdentity.GetCurrent().Name);

                        // Impersonate using the token handle returned by LogonUser.
                        using (WindowsIdentity newId = new WindowsIdentity(tokenHandle))
                        {
                            WindowsImpersonationContext impersonatedUser = newId.Impersonate();

                            ExecuteInput(ConnectString); // execute it

                            impersonatedUser.Undo(); // which reverts to self
                        }
                        if (tokenHandle != IntPtr.Zero) NativeMethods.CloseHandle(tokenHandle);

                        // Check the identity.
                        if (_DEBUGMODE) Console.WriteLine("After impersonation: " + WindowsIdentity.GetCurrent().Name);

                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(Msg(Properties.Resources.locImpersonateErr), ex.Message);
                        throw;
                    }
                }
                else // no impersonation needed
                {
                    try
                    {
                       ExecuteInput(ConnectString); // execute it
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(Msg(Properties.Resources.locImpersonateErr), ex.Message);
                        throw;
                    }
                }
                CloseFiles();
            }
            catch (Exception ex)
            {
                Console.WriteLine(Msg(Properties.Resources.locFailedErr), ex.Message);
                return 1; // error raised
            }
            if (Option_o_specified && ExceptionSeen)
                Console.WriteLine(Msg(Properties.Resources.locCheckOutputForErr));
            return (ExceptionSeen) ? 1 : 0;
        }

        // Regex match against input string??
        private static bool InputMatch(string regexString, StringBuilder sb)
        {
            string s = sb.ToString();
            bool b = Regex.IsMatch(s, regexString);
            return b;
        }

        // Rest of the functions below are supporting routines.

        // --------------------------------------------------------------------
        // Supporting routine -- perform scripting variable substitution
        private static void SubstituteScriptingVariables(StringBuilder sb)
        {
            Regex expression = new Regex(ScriptingVarRefRegex);

            foreach (Match m in expression.Matches(sb.ToString()))
            {
                // Pick out just the scripting variable name by remove leading and
                // trailing characters of the scripting variable
                string name = m.ToString().Replace("$(", "").Replace(")", "");

                // Perform the substitution of scripting variable to its value
                if (substituteWith.ContainsKey(name))
                {
                    // -v or system-reserved replacement
                    sb.Replace(m.ToString(), substituteWith[name]);
                }
                else if ((Environment.GetEnvironmentVariable(name) != null) &&
                        (!name.StartsWith("ASCMD", StringComparison.CurrentCultureIgnoreCase)))
                {
                    // environment variable replacement (cannot be used for system-reserved)
                    sb.Replace(m.ToString(), Environment.GetEnvironmentVariable(name));
                }
                else
                {
                    // no match found, so eliminate the scripting variable by
                    // replacing it with a blank string
                    sb.Replace(m.ToString(), "");
                }
            }
            if (_DEBUGMODE) Console.WriteLine("After substitution, final input is: " + sb.ToString());
        }

        // --------------------------------------------------------------------
        // Supporting routine -- determine what the connect string should be
        private static string ConnectString
        {
            get
            {
                string cs = "";

                // Build the connect string as required
                // Note: some parameters might have legimite embedded doublequotes "
                //       if so, we marked them with // ** tag
                cs += "Provider=" + Provider;
                if (httpConnection)
                {
                    cs += ";Data Source=\"" + Server + "\"";
                }
                else
                {
                    cs += ";Data Source=\"" + Server;
                    if (Instance.Length > 0) cs += "\\" + Instance;
                    cs += "\"";
                }
                if (Database.Length > 0) cs += ";Database=\"" + Database.Replace("\"", "\"\"") + "\""; //**

                // Add http information, if requested
                if (httpConnection && (UserName.Length > 0))
                {
                    cs += ";UID=\"" + ((Domain.Length > 0) ? Domain + "\\" + UserName : UserName) + "\"";
                    cs += ";PWD=\"" + Password.Replace("\"", "\"\"") + "\""; // **
                }

                // Add timeout information, if requested
                if (Timeout.Length > 0)
                    cs += ";Timeout=" + Timeout.ToString(CultureInfo.CurrentCulture);
                if (ConnectTimeout.Length > 0)
                    cs += ";Connect Timeout=" + ConnectTimeout.ToString(CultureInfo.CurrentCulture);

                // Add extended connectstring option
                if (ExtendedConnectstring.Length > 0)
                    cs += ";" + ExtendedConnectstring.Replace("\"", "\"\""); // **

                // Finally, add our application name :-)
                cs += ";SspropInitAppName=" + AssemblyProduct;

                if (_DEBUGMODE) Console.WriteLine("Connect string: {0}", cs);

                return cs;
            }
        }

        // --------------------------------------------------------------------
        // Execute an input statement (MDX query or XMLA script)
        // *** This is the real work of the program -- the rest is supporting functions ***
        private static void ExecuteInput(string ConnectionString)
        {
            // Wait a random time before connecting.
            // The purpose is during a multi-user load test,
            // to gradually ramp up and overcome potential problems of not being able
            // to connect all clients.
            
            // fix up limits of connect time
            if (ConnectWaitMin < 0) ConnectWaitMin = 0;
            if (ConnectWaitMax < ConnectWaitMin) ConnectWaitMax = ConnectWaitMin;
            if (perfRandom == null) perfRandom = new HighPerformanceRandom(RandomSeed);

            // if we have connect time, then wait it
            if (ConnectWaitMax > 0)
            {
                int iSleepTime = perfRandom.Next(ConnectWaitMin * 1000, ConnectWaitMax * 1000);
                if (_DEBUGMODE) Console.WriteLine("ConnectWait, begin sleeping {0} millisec.", iSleepTime);
                System.Threading.Thread.Sleep(iSleepTime);
                if (_DEBUGMODE) Console.WriteLine("ConnectWait, end sleeping.");
            }
            
            Server oServer = new Server();
            //Open up a connection
            try
            {
                oServer.Connect(ConnectionString);
            }
            catch (Exception ex)
            {
                Console.WriteLine(Msg(Properties.Resources.locAmoConnErr), ConnectionString, ex.Message);
                throw;
            }

            // Try to execute the query/script
            try
            {
                // Setup to trace events during execution (only if level is not "duration")
                if (Option_T_specified && !(TraceLevel == "duration") && !(TraceLevel == "duration-result"))
                {
                    // Initialize trace handler
                    oServer.SessionTrace.OnEvent += new TraceEventHandler(SessionTrace_OnEvent);

                    //Write some status stuff
                    if (_DEBUGMODE) Console.WriteLine("Trace connection status to " + Server + " := " + oServer.Connected.ToString(CultureInfo.CurrentCulture));
                    if (_DEBUGMODE) Console.WriteLine("Server := " + oServer.Name + " (Session:" + oServer.SessionID.ToString(CultureInfo.CurrentCulture) + ")");

                    // Start the trace
                    oServer.SessionTrace.Start();
                }

                // Execute the input batches
                ExecuteBatches(oServer);

                // Stop the trace (if running)            
                if (!oServer.SessionTrace.IsStarted) oServer.SessionTrace.Stop();

            }
            catch (Exception ex)
            {
                Console.WriteLine(Msg(Properties.Resources.locAdomdExecutionErr), ex.Message);
                oServer.Dispose();
                throw;
            }

            //Disconnect and end the session on the server
            try
            {
                oServer.Disconnect(true);
            }
            catch (Exception ex)
            {
                Console.WriteLine(Msg(Properties.Resources.locAmoDisconnErr), ex.Message);
                throw;
            }

            oServer.Dispose();
        }

        // --------------------------------------------------------------------
        // Execute the batches in the input stream (sb)
        //   A batch is a portion of the input stream separated by "GO" commands, i.e.
        //      <batch>
        //      GO
        //      <batch>
        //      GO
        // 
        private static void ExecuteBatches(Server oServer)
        {
            Regex expression = new Regex(BatchRegex,
                RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.Multiline);

            // pickup the input stream, append a GO command and parse it
            MatchCollection matches = expression.Matches(sb.ToString() + "\ngo\n");
            if (matches.Count > 1) Output(null, DateTime.Now, DateTime.Now, "<multiple-batches>");

            bool DidFirstQuery = false;
            foreach (Match m in matches)
            {
                // Wait a random think time after each query.
                // The purpose is during a multi-user load test.
                if (DidFirstQuery)
                {
                    // Does the exit file exist? If so, break out of the foreach Match loop early
                    if (File.Exists(ExitFile)) break;

                    // Fix up limits of think time
                    if (ThinkTimeMin < 0) ThinkTimeMin = 0;
                    if (ThinkTimeMax < ThinkTimeMin) ThinkTimeMax = ThinkTimeMin;
                    if (perfRandom == null) perfRandom = new HighPerformanceRandom(RandomSeed);

                    // If we have a think time, then wait it
                    if (ThinkTimeMax > 0)
                    {
                        int iSleepTime = perfRandom.Next(ThinkTimeMin * 1000, ThinkTimeMax * 1000);
                        if (_DEBUGMODE) Console.WriteLine("ThinkTime, begin sleeping {0} millisec.", iSleepTime);
                        System.Threading.Thread.Sleep(iSleepTime);
                        if (_DEBUGMODE) Console.WriteLine("ThinkTime, end sleeping.");
                    }
                }

                // Pick out just the scripting variable name by remove leading and
                // trailing characters of the scripting variable
                string fullText = m.Value;
                StringBuilder batch = new StringBuilder(fullText.Substring(0, fullText.Length - 3).Trim());

                if (_DEBUGMODE) Console.WriteLine("Batch input is: " + batch.ToString());
                if (batch.Length > 0) ExecuteBatch(oServer, InputFileMarker(batch)); // fire the batch
                DidFirstQuery = true;

            } // loop for next batch

            if (matches.Count > 1) Output(null, DateTime.Now, DateTime.Now, "</multiple-batches>");
        }

        private static StringBuilder InputFileMarker(StringBuilder inp)
        {
            try
            {
                Regex expression = new Regex(InputFileRegex,
                        RegexOptions.Compiled | RegexOptions.IgnoreCase); // | RegexOptions.Multiline);

                // pickup the input stream, append a GO command and parse it
                MatchCollection matches = expression.Matches(inp.ToString());

                if (matches.Count != 1) return inp;

                InputFile = matches[0].Groups["inputFile"].ToString();
                StringBuilder sb = new StringBuilder(matches[0].Groups["batchText"].ToString());

                if (_DEBUGMODE) Console.WriteLine("Setting Input File to: {0}\nSetting batch to: {1}", InputFile, sb.ToString());

                return sb;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Parse error: {0}", ex.Message);
                throw;
            }
        }

        // Now execute the batch itself (which is the lowest level of command to ascmd)
        private static void ExecuteBatch(Server oServer, StringBuilder inp)
        {
            // The result string for the execution
            string Result;

            // Wrap a stopwatch around execution
            DateTime StartTime = DateTime.Now;
            DateTime EndTime = DateTime.Now; 
            Stopwatch sw = new Stopwatch();

            // If this is not an XMLA command (or Discover/Execute raw XMLA request) then
            // we assume that it is an un-encoded Statement without the XML tag.
            // This allows the end-user the convience of just entering a MDX or DMX statement
            // and we will wrap it for them.
            if (!InputMatch(XMLACommandRegex, inp) && !InputMatch(DiscoverRegex, inp) && !InputMatch(ExecuteRegex, inp))
            {
                string stmt = HttpUtility.HtmlEncode(inp.ToString());
                // Recreate in Input string -- wrapping with <Statement> tags
                inp = new StringBuilder(stmt.Length); // allocates space for new batch -- nothing in it
                inp.AppendFormat("<Statement>{0}</Statement>", stmt); // adds the batch input itself
            }

            // There are two different ways to execute the input: a raw XMLA request or an XMLA command.
            // If this is a raw request, then the batch starts with "Discover" or "Execute", else it is an XMLA command
            if (InputMatch(DiscoverRegex, inp) || InputMatch(ExecuteRegex, inp))
            {
                //--------------------------------------------------------------------------------
                // A raw XMLA request:
                // To run a custom full SOAP Envelope request on Analysis Services server, we
                // need to follow 5 steps:
                // 
                // 1. Start the XML/A request and specify its type (Discover or Execute).
                //    For native connections (direct over TCP/IP with DIME protocol), local 
                //    cube connections and stored procedures connections we don't need to
                //    specify the XML/A request type in advance (an Undefined value is
                //    available). But for HTTP and HTTPS connections we need to.
                //
                // 2. Write the xml request (as an xml soap envelope containing the command
                //    for Analysis Services).
                //
                // 3. End the xml request; this will send the previously written request to the 
                //    server for execution.
                //
                // 4. Read/Parse the xml response from the server (with System.Xml.XmlReader).
                //
                // 5. Close the System.Xml.XmlReader from the previous step, to release the 
                //    connection to be used after.
                //--------------------------------------------------------------------------------

                XmlaRequestType r = XmlaRequestType.Undefined;
                if (InputMatch(DiscoverRegex, inp)) r = XmlaRequestType.Discover;
                if (InputMatch(ExecuteRegex, inp)) r = XmlaRequestType.Execute;

                // Wrap the request with a soap envelope and body
                string s = inp.ToString();
                s = String.Format(CultureInfo.CurrentCulture, SoapEnvFormat, s);

                // Start the stopwatch
                StartTime = DateTime.Now;
                sw.Start();

                // Execute the query/script and gather the results
                XmlWriter _xw = oServer.StartXmlaRequest(r);
                _xw.WriteRaw(s);
                using (XmlReader _xr = oServer.EndXmlaRequest())
                {
                    // Stop the stopwatch
                    sw.Stop();
                    EndTime = DateTime.Now; 

                    // Move in the reader to where the real content begins
                    _xr.MoveToContent();

                    // Skip past the soap envelope and body (if they exist)
                    if (!_xr.EOF && (_xr.Name == "soap:Envelope")) _xr.Read();
                    if (!_xr.EOF && (_xr.Name == "soap:Body")) _xr.Read();

                    // Gather the results and output them
                    Result = GatherResults(_xr);

                    // Close the System.Xml.XmlReader, to release the connection for
                    // future use.
                    _xr.Close();
                }
            }
            else
            {
                //--------------------------------------------------------------------------------
                // An XMLA Command request:

                StartTime = DateTime.Now;
                sw.Start(); // start the stopwatch
                XmlaResultCollection _xrc = oServer.Execute(inp.ToString());
                sw.Stop();
                EndTime = DateTime.Now;

                // Gather the results and output them
                Result = GatherResults(_xrc);
            }
            // Output the result
            Output(sw, StartTime, EndTime, Result);

            // If requested, wait for tracing to finish
            if (Option_T_specified)
            {
                if ((TraceLevel == "duration") || (TraceLevel == "duration-result"))
                {
                    DurationTrace(sw, Result);
                }
                else
                {
                    // is high, medium, low
                    WaitForTraceToFinish();
                }
            }
        }

        // --------------------------------------------------------------------
        // Supporting routines -- gather the results

        private static string GatherResults(XmlReader Results)
        {
            string s = Results.ReadOuterXml();

            // -----------------------------------
            // Look for errors.
            // -----------------------------------
            // As an initial pass, we'll just look for some special tags in the
            // stream. This works because the underlying data in the xml stream
            // is html encoded -- thus the only tags that should exist is if there
            // are errors
            if (s.Contains("</soap:Fault>") ||   // xsd-detected errors
                s.Contains("</Exception>")      // server-detected errors
                )
            {
                ExceptionSeen = true; // tell the main program that we saw errors
            }

            return s;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1800:DoNotCastUnnecessarily")]
        private static string GatherResults(XmlaResultCollection Results)
        {
            // XML namespace constants used
            const string xmlns_xmla = "xmlns=\"urn:schemas-microsoft-com:xml-analysis\"";
            const string xmlns_multipleresults = "xmlns=\"http://schemas.microsoft.com/analysisservices/2003/xmla-multipleresults\"";
            const string xmlns_mddataset = "xmlns=\"urn:schemas-microsoft-com:xml-analysis:mddataset\"";
            const string xmlns_xsi = "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"";
            const string xmlns_xsd = "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"";
            const string xmlns_empty = "xmlns=\"urn:schemas-microsoft-com:xml-analysis:empty\"";
            const string xmlns_exception = "xmlns=\"urn:schemas-microsoft-com:xml-analysis:exception\"";

            // Format strings constants used
            const string fs_Error = "<Error ErrorCode=\"{0}\" Description=\"{1}\" Source=\"{2}\" HelpFile=\"{3}\" />";
            const string fs_Warning = "<Warning WarningCode=\"{0}\" Description=\"{1}\" Source=\"{2}\" HelpFile=\"{3}\" />";

            // Start to build the output
            StringBuilder _output = new StringBuilder(
                String.Format(CultureInfo.CurrentCulture, "<return {0}>", xmlns_xmla));

            // If there are multiple resultsets, then add the grouping element 
            if (Results.Count > 1)
                _output.Append(String.Format(CultureInfo.CurrentCulture,
                    "<results {0}>", xmlns_multipleresults));

            // loop through each result in the result set
            foreach (XmlaResult _xr in Results)
            {
                // Is there a value for this result?
                if (_xr.Value.Length > 0)
                {   // Yes, indicate its type 
                    _output.Append(String.Format(CultureInfo.CurrentCulture,
                        "<root {0} {1} {2}>", xmlns_mddataset, xmlns_xsi, xmlns_xsd));
                    _output.Append(_xr.Value); // include the value in the stream
                }
                else
                {   // Nope, output the empty set for the root
                    _output.Append(String.Format(CultureInfo.CurrentCulture,
                        "<root {0}>", xmlns_empty));
                }

                // Do we have some messages associated with the result? If so, output them
                if (_xr.Messages.Count > 0)
                {
                    if (ErrorsExist(_xr))
                        _output.Append(String.Format(CultureInfo.CurrentCulture,
                            "<Exception {0} />", xmlns_exception));

                    // Output the messages
                    _output.Append(String.Format(CultureInfo.CurrentCulture,
                        "<Messages {0}>", xmlns_exception));
                    foreach (XmlaMessage _xm in _xr.Messages)
                    {
                        if (_xm is XmlaError) // determine type type
                        {
                            ExceptionSeen = true;    // ERROR bubbles up for the "main" return value

                            int ErrorCode = ((XmlaError)_xm).ErrorCode;
                            _output.Append(String.Format(CultureInfo.CurrentCulture, fs_Error,
                                ((uint)ErrorCode).ToString(CultureInfo.CurrentCulture),
                                HttpUtility.HtmlEncode(_xm.Description), _xm.Source, _xm.HelpFile));

                        }
                        else
                        {
                            int WarningCode = ((XmlaWarning)_xm).WarningCode;
                            _output.Append(String.Format(CultureInfo.CurrentCulture, fs_Warning,
                                ((uint)WarningCode).ToString(CultureInfo.CurrentCulture),
                                HttpUtility.HtmlEncode(_xm.Description), _xm.Source, _xm.HelpFile));
                        }
                    }
                    _output.Append("</Messages>");
                }
                _output.Append("</root>");
            }
            if (Results.Count > 1) _output.Append("</results>");

            _output.Append("</return>");

            // Return the string we've constructed
            return _output.ToString();
        }

        private static bool ErrorsExist(XmlaResult _xr)
        {
            bool ret = false;
            foreach (XmlaMessage _xm in _xr.Messages)
            {
                if (_xm is XmlaError) ret = true;
            }
            return ret;
        }

        private static void WaitForTraceToFinish()
        {
            int delay = Int32.Parse(TraceTimeout, CultureInfo.CurrentCulture);
            TraceTimeoutCount = TraceTimeoutCountReset = delay * PollingInterval; // TraceTimeoutCount is in 1/4 seconds
            // Wait for trace to start to flow
            while (!TraceStarted) { Thread.Sleep(1); } // loop every 20ms waiting for trace to start
            // Wait BeginEndBlockCount becomes 0 or TraceTimeoutCount expires
            while (TraceTimeoutCount > 0)
            { // loop forever until TraceFinished
                if (BeginEndBlockCount == 0) return;
                Thread.Sleep(1000 / PollingInterval); // wait a polling interval
                TraceTimeoutCount--;
            }
            // TraceTimeoutCount expired -- just exit
        }

        // -------------------------------------------------------------------
        // Supporting routines which handle the trace events
        // Remove control characters, i.e. LF, CR, TAB, etc. and replace them with spaces
        private static string RemoveControlChars(string s)
        {
            StringBuilder sb = new StringBuilder(s);
            for (int i = 0; i < s.Length; i++)
            {
                if (Char.IsControl(sb[i]))
                    sb[i] = ' '; // replace all control characters with a space
            }
            return sb.ToString();
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        static void SessionTrace_OnEvent(object sender, TraceEventArgs e)
        {
            string EventClass = e.EventClass.ToString();
            //if (_DEBUGMODE) Console.WriteLine("SessionTrace_OnEvent fired");

            TraceStarted = true; // indicated that we have started to see trace events

            // keep the begin-end block count
            if (EventClass.Contains("Begin")) BeginEndBlockCount++;
            if (EventClass.Contains("End") && (BeginEndBlockCount > 0)) BeginEndBlockCount--;

            // based on the trace level, decide if we should record the event
            // high just falls through -- everything is recorded
            if (TraceLevel == "medium" || TraceLevel == "low")
            {
                if ((EventClass == "ProgressReportCurrent") ||
                    //(EventClass == "ProgressReportBegin") || 
                    //(EventClass == "ProgressReportEnd") || 
                    (EventClass == "Notification")) return; // ignore this event
            }
            if (TraceLevel == "low")
            {
                if (!(EventClass.Contains("End") ||
                    EventClass.Contains("Error"))) return; // if EventClass doesn't contain 'End' or 'Error', ignore this event
            }

            switch (TraceFormat)
            {
                case "text":  // a text interpretation of the event
                    {
                        StringBuilder tm = new StringBuilder(); // trace message
                        tm.Append(e.CurrentTime.ToString(CultureInfo.CurrentCulture));
                        tm.Append(", " + e.EventClass.ToString());
                        tm.Append("." + e.EventSubclass.ToString());
                        foreach (TraceColumn tc in Enum.GetValues(typeof(TraceColumn)))
                        {
                            if ((tc.ToString() != "CurrentTime") &&
                                (tc.ToString() != "EventClass") &&
                                (tc.ToString() != "EventSubclass"))
                            {
                                string val = e[tc];
                                if (null != val)
                                {
                                    if (tm.Length != 0) tm.Append(", ");
                                    string v = tc + ": " + RemoveControlChars(val);
                                    tm.Append(v);
                                }
                            }
                        }
                        // Note: For text, output nothing for 'Result' since it is alwasy blank for trace events

                        Trace(tm.ToString()); // write trace line
                        break;
                    }
                case "csv":	// a csv interpreation of the event
                    {
                        StringBuilder tm = new StringBuilder();
                        tm.Append(e.CurrentTime.ToString(CultureInfo.CurrentCulture));
                        tm.Append(TraceDelim + e.EventClass.ToString());
                        tm.Append(TraceDelim + e.EventSubclass.ToString());
                        foreach (TraceColumn tc in Enum.GetValues(typeof(TraceColumn)))
                        {
                            if ((tc.ToString() != "CurrentTime") &&
                                (tc.ToString() != "EventClass") &&
                                (tc.ToString() != "EventSubclass"))
                            {
                                string val = e[tc];
                                if (tm.Length != 0) tm.Append(TraceDelim);
                                if (null != val) tm.Append(RemoveControlChars(val));
                            }
                        }
                        tm.Append(TraceDelim); // For csv, 'Result' is always blank for trace events

                        Trace(tm.ToString()); // write trace line
                        break;
                    }
            }
            TraceTimeoutCount = TraceTimeoutCountReset; // reset the no activity timer
        }

        private static void DurationTrace(Stopwatch sw, string Result)
        {
            string now = DateTime.Now.ToString(CultureInfo.CurrentCulture);
            string Duration = sw.ElapsedMilliseconds.ToString(CultureInfo.CurrentCulture);
            switch (TraceFormat)
            {
                case "text":
                    {
                        StringBuilder tm = new StringBuilder(); // trace message
                        tm.Append(now);
                        tm.Append(", Duration: " + Duration);
                        tm.Append(", DatabaseName: " + Database);
                        tm.Append(", TextData: " + RemoveControlChars(sb.ToString()));
                        tm.Append(", ServerName: " + Server);
                        if (TraceLevel == "duration-result") tm.Append(", Result: " + Result);
                        Trace(tm.ToString()); // write trace line
                        break;
                    }
                case "csv":	// a csv interpreation of the event
                    {
                        StringBuilder tm = new StringBuilder();
                        tm.Append(now);
                        tm.Append(TraceDelim); // EventClass
                        tm.Append(TraceDelim); // EventSubclass
                        foreach (TraceColumn tc in Enum.GetValues(typeof(TraceColumn)))
                        {
                            if ((tc.ToString() != "CurrentTime") &&
                                (tc.ToString() != "EventClass") &&
                                (tc.ToString() != "EventSubclass"))
                            {
                                switch (tc.ToString())
                                {
                                    case "Duration":
                                        {
                                            tm.Append(TraceDelim);
                                            tm.Append(Duration);
                                            break;
                                        }
                                    case "DatabaseName":
                                        {
                                            tm.Append(TraceDelim);
                                            tm.Append(Database);
                                            break;
                                        }
                                    case "TextData":
                                        {
                                            tm.Append(TraceDelim);
                                            string val = sb.ToString();
                                            tm.Append(RemoveControlChars(val));
                                            break;
                                        }
                                    case "ServerName":
                                        {
                                            tm.Append(TraceDelim);
                                            tm.Append(Server);
                                            break;
                                        }
                                    default:
                                        {
                                            tm.Append(TraceDelim);
                                            break;
                                        }
                                }
                            }
                        }
                        tm.Append(TraceDelim);
                        if (TraceLevel == "duration-result") tm.Append(Result);

                        Trace(tm.ToString()); // write trace line
                        break;
                    }
            }
        }

        // --------------------------------------------------------------------
        // Supporting routines -- to generate lines in the "Output and Trace files
        private static void Output(Stopwatch sw, DateTime StartTime, DateTime EndTime, string msg)
        {
            if (Option_o_specified)
            {
                // Add support for NUL device
                if (!(OutputFile.Equals("NUL", StringComparison.CurrentCultureIgnoreCase)) &&
                    !(OutputFile.StartsWith("NUL:", StringComparison.CurrentCultureIgnoreCase)))
                {
                    // file open delayed until absolutely needed (otherwise we end up overwriting it
                    // unnecessarily
                    if (!IsOutputFileOpen)
                    {
                        // open the file
                        try
                        {
                            sw_out = new StreamWriter(OutputFile, false, System.Text.Encoding.UTF8); // does an overwrite
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine(Msg(Properties.Resources.locOutputFileOpenErr), ex.Message);
                            throw;
                        }
                        IsOutputFileOpen = true;
                    }
                    sw_out.WriteLine(msg);
                    sw_out.Flush();
                }
            }
            else
            {
                Console.WriteLine(msg);
            }
            if ((OutputResultStatFile.Length > 0) && sw != null)
            {
                // Add support for NUL device
                if (!(OutputResultStatFile.Equals("NUL", StringComparison.CurrentCultureIgnoreCase)) &&
                    !(OutputResultStatFile.StartsWith("NUL:", StringComparison.CurrentCultureIgnoreCase)))
                {
                    // file open delayed until absolutely needed (otherwise we end up overwriting it
                    // unnecessarily
                    if (!IsOutputResultStatFileOpen)
                    {
                        // open the file
                        try
                        {
                            sw_outResultStat = new StreamWriter(OutputResultStatFile, true, System.Text.Encoding.UTF8); // does an overwrite
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine(Msg(Properties.Resources.locOutputFileOpenErr), ex.Message);
                            throw;
                        }
                        IsOutputResultStatFileOpen = true;
                    }
                    OutputResultStatInfoToFile(sw, StartTime, EndTime, msg);
                }
            }
        }

        // Output the result statistics to the output stream.
        // The format is CSV.
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        private static void OutputResultStatInfoToFile(Stopwatch sw, DateTime StartTime, DateTime EndTime, string xmlResultString)
        {
            // Try to read the server xml output.
            //
            // InputFile = Input file name.
            // TODO: We should have more information here to match up.  Also need hash of input query.
            // GotError = Error parsing or error from query.
            // NumCols = Number of columns, based on axis0.
            // NumRows = Number of rows, based on axis1.
            // NumCellsTotal = Number of cells total.  Calculated from virtual space of the axes.
            // NumCellsNonEmpty = Number of cells having a <Value> attribute.  
            //    This includes error cells, and cells that the server sends that have <null> for value,
            //    which might be the result of calculations.
            // NumCellsEmpty = Number of cells not having a <Value> element.  Calculated from NumCellsTotal-NumCellsNonEmpty.
            //    Note that the server might send <Action> or other elements in the <Cell>.
            // NumCellsError = Number of cells having an <Error> element in the <Value> element.

            // First output a header line if needed.
            // This is nice for CSV output to read in Excel for example.
            if ((!Option_NoResultStatHeader_specified) && (sw_outResultStat.BaseStream.Length <= 0))
                sw_outResultStat.WriteLine("InputFile,RunInfo,StartTime,EndTime,Duration,GotError,NumCols,NumRows,NumCellsTotal,NumCellsNonEmpty,NumCellsEmpty,NumCellsError");

            StringReader strReader = new StringReader(xmlResultString);
            XmlTextReader xmlreader = new XmlTextReader(strReader);
            bool fGotError = false;
            bool fGotQueryError = false;
            bool fParsingAxisRows = false;
            bool fParsingAxisCols = false;
            bool fParsingAxisPags = false;
            bool fParsingCell = false;
            bool fParsingValue = false;
            int NumCols = -1;
            int NumRows = -1;
            int NumPags = -1;
            int NumCellsValue = 0;
            int NumCellsError = 0;

            try
            {
                // Quickly skip over info at the beginning we don't currently use.
                // No, must be able to recognize entire query error, which is <Exception>.
                //xmlreader.ReadToFollowing("Axes");

                while (xmlreader.Read() && !fGotError)
                {
                    switch (xmlreader.NodeType)
                    {
                        case XmlNodeType.Element:
                            switch (xmlreader.Name)
                            {
                                case "Exception":
                                    // This is an error in the mdx query.
                                    //    <Exception xmlns="urn:schemas-microsoft-com:xml-analysis:exception"></Exception>
                                    //    <Messages xmlns="urn:schemas-microsoft-com:xml-analysis:exception">
                                    //      <Error ErrorCode="3238658057" Description="Query (19, 1) The member &apos;[Z_TY Str Stktrn]&apos; was not found in the cube when the string, [Measures].[Z_TY Str Stktrn], was parsed." Source="Microsoft SQL Server 2005 Analysis Services" HelpFile=""></Error>
                                    //    </Messages>
                                    fGotQueryError = true;
                                    break;
                                case "Axis":
                                    fParsingAxisRows = false;
                                    fParsingAxisCols = false;
                                    fParsingAxisPags = false;
                                    xmlreader.MoveToFirstAttribute();
                                    if (xmlreader.Name != "name")
                                    {
                                        // todo: Need to use Properties.Resources for error messages.
                                        Console.WriteLine("Warning: Expecting result 'Axis' element to have 'name' attribute");
                                        fGotError = true;
                                        break;
                                    }
                                    if (xmlreader.Value == "Axis0")
                                    {
                                        fParsingAxisCols = true;
                                        NumCols = 0;
                                    }
                                    else if (xmlreader.Value == "Axis1")
                                    {
                                        fParsingAxisRows = true;
                                        NumRows = 0;
                                    }
                                    else if (xmlreader.Value == "Axis2")
                                    {
                                        fParsingAxisPags = true;
                                        NumPags = 0;
                                    }
                                    //else if (xmlreader.Value == "SlicerAxis")
                                    break;
                                case "Tuple":
                                    if (fParsingAxisCols)
                                        NumCols++;
                                    else if (fParsingAxisRows)
                                        NumRows++;
                                    else if (fParsingAxisPags)
                                        NumPags++;
                                    // Skip children of this node (for speed).
                                    // No, cannot use, this causes it to skip other "tuple" siblings.
                                    //xmlreader.Skip();
                                    break;
                                case "Cell":
                                    // Note that we consider the case where actions are specified,
                                    // but there is no <value> node underneath the <cell> node.
                                    //
                                    // Here is an example of a cell we will not count as NumCellsNonEmpty because it is missing <Value>.
                                    //      <Cell CellOrdinal="18">
                                    //        <ActionType>0</ActionType>
                                    //      </Cell>
                                    //
                                    // Here is an example of a cell error:
                                    //      <Cell CellOrdinal="8052">
                                    //        <Value>
                                    //          <Error>
                                    //            <ErrorCode>3238658057</ErrorCode>
                                    //            <Description>MdxScript(Edgars) (6267, 1) The member '[53 Weeks Ave Str Stk]' was not found in the cube when the string, [Measures].[53 Weeks Ave Str Stk], was parsed.</Description>
                                    //          </Error>
                                    //        </Value>
                                    fParsingCell = true;
                                    break;

                                    // Note that we do not care about the Cell Ordinal, only the number of cells we see.
                                    /*
                                    if (!xmlreader.HasAttributes)
                                    {
                                        // Need to use Properties.Resources for error messages.
                                        Console.WriteLine("Warning: Expecting result 'Cell' element to have 'CellOrdinal' attribute but it is missing.");
                                        fGotError = true;
                                        break;
                                    }
                                    xmlreader.MoveToFirstAttribute();
                                    if (xmlreader.Name != "CellOrdinal")
                                    {
                                        // Need to use Properties.Resources for error messages.
                                        Console.WriteLine("Warning: Expecting result 'Cell' element to have 'CellOrdinal' attribute");
                                        fGotError = true;
                                        break;
                                    }
                                    int iCellOrdinal;
                                    if (!int.TryParse(xmlreader.Value, out iCellOrdinal))
                                    {
                                        // Need to use Properties.Resources for error messages.
                                        Console.WriteLine("Warning: Expecting result 'Cell' element to have 'CellOrdinal' attribute with number, found '{0}'", xmlreader.Value);
                                        fGotError = true;
                                        break;
                                    }
                                    NumCells = Math.Max(NumCells, iCellOrdinal + 1);
                                    break;
                                    */

                                case "Value":
                                    if (fParsingCell)
                                    {
                                        fParsingValue = true;
                                        NumCellsValue++;
                                    }
                                    break;
                                case "Error":
                                    if (fParsingCell && fParsingValue)
                                    {
                                        // Note that <Error> is inside <Value>.
                                        // Therefore NumCellsValue includes NumCellsError.
                                        NumCellsError++;
                                    }
                                    break;
                            }
                            break;
                        case XmlNodeType.EndElement:
                            switch (xmlreader.Name)
                            {
                                case "Cell":
                                    fParsingCell = false;
                                    break;
                                case "Value":
                                    fParsingValue = false;
                                    break;
                            }
                            break;
                        case XmlNodeType.Text:
                        case XmlNodeType.CDATA:
                        case XmlNodeType.Comment:
                        case XmlNodeType.XmlDeclaration:
                        case XmlNodeType.Document:
                        case XmlNodeType.DocumentType:
                        case XmlNodeType.EntityReference:
                        case XmlNodeType.Whitespace:
                        default:
                            break;
                    }
                }

                // Replace the contents only if we were entirely successful.
                if (xmlreader.EOF)
                {
                    // Note that we handle only up to 3 dimensions here.
                    // Some UI tools internally use 3 dimensions.
                    // We set each to -1 to begin with, and set to 0 when first obtained.
                    // so -1 means axis is not present, and 0 means axis is present with 0 tuples.
                    // For example, if query does Non Empty on rows and there are 0, then NumCellsTotal = 0.
                    int NumCellsTotal = 0;
                    if (NumCols >= 0)
                        NumCellsTotal = NumCols;
                    if (NumRows >= 0)
                        NumCellsTotal *= NumRows;
                    if (NumPags >= 0)
                        NumCellsTotal *= NumPags;
                    int NumCellsEmpty = NumCellsTotal - NumCellsValue;

                    // InputFile,RunInfo,StartTime,EndTime,Duration,GotError,NumCols,NumRows,NumCellsTotal,NumCellsNonEmpty,NumCellsEmpty,NumCellsError
                    sw_outResultStat.WriteLine("{0},{1},{2},{3},{4:#.000},{5},{6},{7},{8},{9},{10},{11}", 
                        InputFile,
                        RunInfo.ToString(CultureInfo.CurrentCulture),
                        StartTime.ToString("s", CultureInfo.CurrentCulture),
                        EndTime.ToString("s", CultureInfo.CurrentCulture),
                        sw.Elapsed.TotalSeconds,
                        fGotQueryError ? 1 : 0,
                        NumCols,
                        NumRows, 
                        NumCellsTotal, 
                        NumCellsValue, // NumCellsNonEmpty
                        NumCellsEmpty, 
                        NumCellsError);
                    sw_outResultStat.Flush();
                    return;
                }
            }
            catch (System.Xml.XmlException ex)
            {
                //@todo: Do we need another error message, or re-use this one?
                Console.WriteLine(Msg(Properties.Resources.locFailedErr), ex.Message);
                // We ignore exceptions from XML.
                //throw;
            }
            catch (Exception ex)
            {
                //@todo: Do we need another error message, or re-use this one?
                Console.WriteLine(Msg(Properties.Resources.locFailedErr), ex.Message);
                throw;
            }
            sw_outResultStat.WriteLine("-1,-1,-1,-1");
            return;
        }

        private static void Trace(string msg)
        {

            if (!IsTraceFileOpen)
            {
                bool appendFlag;

                // file open delayed until absolutely needed
                try
                {
                    // if doing duration trace and file already exists, then don't overwrite
                    // but instead do an append
                    appendFlag = (((TraceLevel == "duration") || (TraceLevel == "duration-result")) &&
                                        File.Exists(TraceFile)) ? true : false;
                    sw_trace = new StreamWriter(TraceFile, appendFlag, System.Text.Encoding.UTF8);
                }
                catch (Exception ex)
                {
                    Console.WriteLine(Msg(Properties.Resources.locTraceFileOpenErr), ex.Message);
                    throw;
                }
                IsTraceFileOpen = true;

                // Ok Trace file is now ready to go

                // If csv trace file format and we are not appending to the end, then
                // output the header line in the trace
                if ((TraceFormat == "csv") && !appendFlag)
                {
                    StringBuilder tm = new StringBuilder();
                    tm.Append("CurrentTime" + TraceDelim +
                        "EventClass" + TraceDelim + "EventSubclass");
                    foreach (TraceColumn tc in Enum.GetValues(typeof(TraceColumn)))
                    {
                        if ((tc.ToString() != "CurrentTime") &&
                            (tc.ToString() != "EventClass") &&
                            (tc.ToString() != "EventSubclass"))
                        {
                            tm.Append(TraceDelim);
                            tm.Append(tc);
                        }
                    }
                    tm.Append(TraceDelim + "Result");

                    Trace(tm.ToString());
                }
            }

            // write out the trace line
            try
            {
                sw_trace.WriteLine(msg);
            }
            catch (Exception ex)
            {
                Console.WriteLine(Msg(Properties.Resources.locTraceWriteErr), ex.Message);
                throw;
            }
        }

        // --------------------------------------------------------------------
        // Supporting routines -- close all files
        private static void CloseFiles()
        {
            // OK, we are all done. Perform some file cleanup and exit.
            if (IsOutputFileOpen) CloseFile(sw_out, Msg(Properties.Resources.locOutputFileCloseErr));
            if (IsTraceFileOpen) CloseFile(sw_trace, Msg(Properties.Resources.locTraceFileCloseErr));
        }

        private static void CloseFile(StreamWriter sw, string errorMsg)
        {
            try
            {
                sw.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine(errorMsg, ex.Message);
                throw;
            }
        }
        
        // --------------------------------------------------------------------
        // Supporting routine -- to parse the command line
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        private static bool ParseArgs(string[] args)
        {
            if (args.Length == 0) // nothing on the command-line
            {
                // as a minimum -i or -Q must be specified
                Console.WriteLine(Msg(Properties.Resources.locInpEitherErr));
                ShowHelp(); return false;
            }

            GetScriptingVariables(); // Get scripting variables from the OS

            // Now loop through the command-line args
            for (int i = 0; i < args.Length; i++)
            {
                string arg = args[i].ToString(CultureInfo.CurrentCulture);
                if (_DEBUGMODE) Console.WriteLine(arg);

                switch (arg)
                {
                    case "/?":  // Unix way of requesting help
                    case "-?":	// and this is the Windows way :-)
                        {
                            ShowHelp();
                            return false;
                        }
                    case "-U":	// User Id
                        {
                            if (Option_U_specified) return OptionSeen("-U");
                            Option_U_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-U"); // option must have an argument
                            UserName = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + UserName);
                            break;
                        }
                    case "-P":	// Password
                        {
                            if (Option_P_specified) return OptionSeen("-P");
                            Option_P_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-P"); // option must have an argument
                            Password = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + Password);
                            break;
                        }
                    case "-S":	// Server
                        {
                            if (Option_S_specified) return OptionSeen("-S");
                            Option_S_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-S"); // option must have an argument
                            Server = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + Server);
                            break;
                        }
                    case "-d":	// Database
                        {
                            if (Option_d_specified) return OptionSeen("-d");
                            Option_d_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-d"); // option must have an argument
                            Database = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + Database);
                            break;
                        }
                    case "-t":	// Timeout (for query)
                        {
                            if (Option_t_specified) return OptionSeen("-t");
                            Option_t_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-t"); // option must have an argument
                            Timeout = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + Timeout.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-tc":	// Timeout (for connections)
                        {
                            if (Option_tc_specified) return OptionSeen("-tc");
                            Option_tc_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-tc"); // option must have an argument
                            ConnectTimeout = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + ConnectTimeout.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-i":	// InputFile
                        {
                            // Allow multiple input files.
                            //if (Option_i_specified) return OptionSeen("-i");
                            Option_i_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-i"); // option must have an argument
                            InputFile = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + InputFile);
                            // Validate the file exists
                            if (File.Exists(InputFile))
                            {
                                // Read in the query or script from the input file
                                try
                                {
                                    // Force the reader to be UTF8 and to look for byte-order marker in file
                                    StreamReader sr = new StreamReader(InputFile, System.Text.Encoding.UTF8, true);
                                    if (sb.Length == 0)
                                    {
                                        sb.AppendFormat(InputFileFormat,InputFile.ToString());
                                        sb.Append(sr.ReadToEnd().Trim());
                                        TryParseAsMultiUserXML(ref sb);
                                    }
                                    else
                                    {
                                        StringBuilder sbTmp = new StringBuilder(sr.ReadToEnd().Trim());
                                        TryParseAsMultiUserXML(ref sbTmp);
                                        sb.Append("\ngo\n");
                                        sb.AppendFormat("**InputFile: {0}\n",InputFile.ToString());
                                        sb.Append(sbTmp);
                                    }
                                }
                                catch (Exception ex)
                                {
                                    Console.WriteLine(Msg(Properties.Resources.locInpFileGeneralErr), InputFile, ex.Message);
                                    throw;
                                }
                                // If input file is empty, return an error.
                                if (sb.Length == 0)
                                {
                                    Console.WriteLine(Msg(Properties.Resources.locInpFileEmptyErr), InputFile);
                                    return false;
                                }
                            }
                            else
                            {
                                // Input file does not exist
                                Console.WriteLine(Msg(Properties.Resources.locInpFileNotExistErr), InputFile);
                                return false;
                            }
                            break;
                        }
                    case "-o":	// OutputFile
                        {
                            if (Option_o_specified) return OptionSeen("-o");
                            Option_o_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-o"); // option must have an argument
                            OutputFile = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + OutputFile);
                            // Make sure the output file name format is OK
                            if (!CheckValidChars(Properties.Resources.locNameOutputFile,
                                        1, -1, "", OutputFile)) return false;
                            break;
                        }
                    case "-oResultStat":	// OutputFile for result statistics
                        {
                            if (Option_oResultStat_specified) return OptionSeen("-oResultStat");
                            Option_oResultStat_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-oResultStat"); // option must have an argument
                            OutputResultStatFile = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + OutputResultStatFile);
                            // Make sure the output file name format is OK
                            if (!CheckValidChars(Properties.Resources.locNameOutputResultStatFile,
                                        1, -1, "", OutputResultStatFile)) return false;
                            break;
                        }
                    case "-NoResultStatHeader":
                        {
                            // no argument
                            if (Option_NoResultStatHeader_specified) return OptionSeen("-NoResultStatHeader");
                            Option_NoResultStatHeader_specified = true;
                            break;
                        }
                    case "-RunInfo":	// run information to be copied into the Result Stat file
                        {
                            if (Option_RunInfo_specified) return OptionSeen("-RunInfo");
                            Option_RunInfo_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-RunInfo"); // option must have an argument
                            RunInfo = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + RunInfo.ToString(CultureInfo.CurrentCulture));
                            // No checks made -- whatever you enter will be placed in the run info sttring
                            break;
                        }
                    case "-RandomSeed":
                        {
                            if (!ParseIntegerArg(args, ref i, "-RandomSeed", ref Option_RandomSeed_specified, ref RandomSeed))
                                return false;
                            break;
                        }
                    case "-ThinkTimeMin":
                        {
                            if (!ParseIntegerArg(args, ref i, "-ThinkTimeMin", ref Option_ThinkTimeMin_specified, ref ThinkTimeMin))
                                return false;
                            break;
                        }
                    case "-ThinkTimeMax":
                        {
                            if (!ParseIntegerArg(args, ref i, "-ThinkTimeMax", ref Option_ThinkTimeMax_specified, ref ThinkTimeMax))
                                return false;
                            break;
                        }
                    case "-ConnectWaitMin":
                        {
                            if (!ParseIntegerArg(args, ref i, "-ConnectWaitMin", ref Option_ConnectWaitMin_specified, ref ConnectWaitMin))
                                return false;
                            break;
                        }
                    case "-ConnectWaitMax":
                        {
                            if (!ParseIntegerArg(args, ref i, "-ConnectWaitMax", ref Option_ConnectWaitMax_specified, ref ConnectWaitMax))
                                return false;
                            break;
                        }
                    case "-Xf":
                        {
                            if (Option_Xf_specified) return OptionSeen("-Xf");
                            Option_Xf_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-Xf"); // option must have an argument
                            ExitFile = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + ExitFile.ToString(CultureInfo.CurrentCulture));
                            
                            // If the exit file already exists, then generate an error
                            if (File.Exists(ExitFile))
                            {
                                Console.WriteLine(Msg(Properties.Resources.locExitFileExistsErr), ExitFile);
                                return false;
                            }
                            break;
                        }
                    case "-Q":	// command line query
                        {
                            if (Option_Q_specified) return OptionSeen("-Q");
                            Option_Q_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-Q"); // option must have an argument
                            Query = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + "\"" + Query + "\"");

                            // If input file is empty, return an error.
                            if (Query.Length == 0)
                            {
                                Console.WriteLine(Msg(Properties.Resources.locOptionQEmptyErr));
                                return false;
                            }
                            else
                            {
                                sb.Append(Query.Trim());
                            }
                            break;
                        }
                    case "-T":	// TraceFile
                        {
                            if (Option_T_specified) return OptionSeen("-T");
                            Option_T_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-T"); // option must have an argument
                            TraceFile = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + TraceFile);
                            // Make sure the trace file name format is OK
                            if (!CheckValidChars(Properties.Resources.locNameTraceFile,
                                        1, -1, "", TraceFile)) return false;
                            break;
                        }
                    case "-Tf":	// Trace file format (only valid if -T is also specified)
                        {
                            if (Option_Tf_specified) return OptionSeen("-Tf");
                            Option_Tf_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-Tf"); // option must have an argument
                            TraceFormat = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + TraceFormat.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-Tl":	// Trace file level (only valid if -T is also specified)
                        {
                            if (Option_Tl_specified) return OptionSeen("-Tl");
                            Option_Tl_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-Tl"); // option must have an argument
                            TraceLevel = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + TraceLevel.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-Td":	// Trace file delimiter (default is "|", vertical bar or pipe)
                        {
                            if (Option_Td_specified) return OptionSeen("-Td");
                            Option_Td_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-Td"); // option must have an argument
                            TraceDelim = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + ExtendedConnectstring.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-Tt":	// Timeout (for trace) -- indicates the amount of inactivity that signals trace is complete
                        {
                            if (Option_Tt_specifed) return OptionSeen("-Tt");
                            Option_Tt_specifed = true;

                            if (i == (args.Length - 1)) return MissingArg("-Tt"); // option must have an argument
                            TraceTimeout = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + TraceTimeout.ToString(CultureInfo.CurrentCulture));
                            break;
                        }
                    case "-xc":	// Extended connectstring
                        {
                            if (Option_xc_specified) return OptionSeen("-xc");
                            Option_xc_specified = true;

                            if (i == (args.Length - 1)) return MissingArg("-xc"); // option must have an argument
                            ExtendedConnectstring = args[++i].ToString(CultureInfo.CurrentCulture);
                            if (_DEBUGMODE) Console.WriteLine("*" + ExtendedConnectstring.ToString(CultureInfo.CurrentCulture));
                            // No checks made -- whatever you enter will be placed on the connect sttring
                            break;
                        }
                    case "-v":	// Set scripting variables
                        {
                            if (Option_v_specified) return OptionSeen("-v");
                            Option_v_specified = true;

                            // -v options are a bit different.
                            // They are in the form '-v name=value name=value name=value'

                            // Loop through arguments until we no longer get a name=value pair 
                            while (i < (args.Length - 1)) // don't loop off the end
                            {
                                string Entry = args[++i].ToString(CultureInfo.CurrentCulture);

                                // look to see if the arg is name=value where name is a
                                // valid scripting variable
                                Regex expression = new Regex(ScriptingVarNameRegex);
                                if (!expression.IsMatch(Entry))
                                {
                                    i -= 1; // Nope, backup and retry the argument as an option 
                                    break;
                                }
                                else
                                {
                                    // Ok if we got here then this is a -v entry
                                    // Parse it into its name=value pair
                                    string[] ParsedEntry = Entry.Split(new Char[] { '=' }, 2);
                                    string name = ParsedEntry[0];
                                    string value = ParsedEntry[1];
                                    if (_DEBUGMODE) Console.WriteLine("-v Name:*" + name);
                                    if (_DEBUGMODE) Console.WriteLine("-v Value:*" + value);
                                    // Validate the name -- it must not start with 'ASCMD'
                                    // that is reservered for command-line options
                                    if (name.StartsWith("ASCMD",
                                                StringComparison.CurrentCultureIgnoreCase))
                                    {
                                        Console.WriteLine(Msg(Properties.Resources.locScriptingVarInvalidNameErr), Entry);
                                        return false;
                                    }
                                    else
                                    {
                                        // add it to substitutionWith table
                                        if (!substituteWith.ContainsKey(name))
                                        {
                                            // Entry is not already known, add it
                                            substituteWith.Add(name, value);
                                        }
                                        else
                                        {
                                            // Entry already there, override it
                                            // Note: this means that if a name is specified
                                            // more than once, then the last name=value pair
                                            // on the command line wins
                                            substituteWith[name] = value;
                                        }
                                    }
                                }
                            }
                            break;
                        }
                    case "-DEBUG":	// set debug mode
                        {
                            // no argument
                            _DEBUGMODE = true;
                            break;
                        }
                    default: // error
                        {
                            Console.WriteLine(Msg(Properties.Resources.locUnknownOptionErr), arg);
                            return false;
                        }
                }
            }

            // Verify the current settings -- returns false if an error found
            if (!ValidateSettings()) return false;

            // Verify input stream
            // 1) command-line must have either -i or -Q, but not both
            // 2) there must be something to actually execute (some script or
            //    query)
            if (Option_i_specified && Option_Q_specified)
            { // both
                Console.WriteLine(Msg(Properties.Resources.locInpNotBothErr));
                return false;
            }
            else if (!(Option_i_specified || Option_Q_specified))
            { // either -i or -Q must be present
                Console.WriteLine(Msg(Properties.Resources.locInpEitherErr));
                return false;
            }
            else if (sb.Length == 0)
            {
                // If we got here then we don't have anything to execute,
                // Note: This is not really needed, because empty checking is 
                // also in both the -Q and -i option parsing
                Console.WriteLine(Msg(Properties.Resources.locNoInpErr)); //
                return false;
            }

            // You cannot run trace over an http or https connection
            if (Option_T_specified && httpConnection)
            {
                Console.WriteLine(Msg(Properties.Resources.locTraceNoHttpErr));
                return false;
            }

            // Set scripting variables
            SetScriptingVariables();

            return true; // All of the options are parsed and files are open ready to go
        }
        // --------------------------------------------------------------------
        // Helper routines for ParseArgs

        private static bool ParseIntegerArg(string[] args, ref int iArg, string OptionString, ref bool OptionSpecified, ref int OptionVal)
        {
            if (OptionSpecified)
                return OptionSeen(OptionString);
            OptionSpecified = true;

            if (iArg == (args.Length - 1)) 
                return MissingArg(OptionString); // option must have an argument

            iArg++;
            if (!Int32.TryParse(args[iArg].ToString((CultureInfo.CurrentCulture)), out OptionVal))
            {
                Console.WriteLine(Msg(Properties.Resources.locIntegerErr), OptionString, args[iArg]);
                return false;
            }

            if (_DEBUGMODE) Console.WriteLine("*" + OptionVal.ToString(CultureInfo.CurrentCulture));
            return true;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        private static bool TryParseAsMultiUserXML( ref StringBuilder sbQuerySet )
        {
            // Try to read the string (which was the input file) using the Multi-User XML format.
            // If we succeed, translate into a big string of queries with "GO" in between.
            // Later code parses the "GO" to create an array of queries.
            //
            // Our goal is to be permissive, and just suck up the first text under <Query> or <Statement>.
            // LoadSim tool creates <Query>.
            // Hopper tool uses <Statement>.

            StringReader strReader = new StringReader(sbQuerySet.ToString());
            XmlTextReader xmlreader = new XmlTextReader(strReader);
            StringBuilder sbCandidateQuerySet = new StringBuilder();
            bool fGotError = false;
            bool fInQuery = false;

            try
            {
                while (xmlreader.Read() && !fGotError)
                {
                    switch (xmlreader.NodeType)
                    {
                    case XmlNodeType.Element:
                        if (xmlreader.Name == "Query" || xmlreader.Name == "Statement")
                            fInQuery = true;
                        break;
                    case XmlNodeType.EndElement:
                        fInQuery = false;
                        break;
                    case XmlNodeType.Text:
                        if (fInQuery)
                        {
                            string strQuery = xmlreader.Value.Trim();
                            if (strQuery.Length > 0)
                            {
                                if (sbCandidateQuerySet.Length > 0)
                                    sbCandidateQuerySet.AppendLine("go");
                                sbCandidateQuerySet.AppendLine(strQuery);
                                fInQuery = false;
                            }
                        }
                        break;
                    case XmlNodeType.CDATA:
                    case XmlNodeType.Comment:
                    case XmlNodeType.XmlDeclaration:
                    case XmlNodeType.Document:
                    case XmlNodeType.DocumentType:
                    case XmlNodeType.EntityReference:
                    case XmlNodeType.Whitespace:
                    default:
                        break;
                    }
                }

                // Replace the contents only if we were entirely successful.
                if (xmlreader.EOF && !fGotError && sbCandidateQuerySet.Length > 0)
                {
                    sbQuerySet = sbCandidateQuerySet;
                    return true;
                }
            }
            catch (System.Xml.XmlException)
            {
                // We ignore exceptions from XML, because this is how they do error handling.
                //System.Diagnostics.Debug.WriteLine(ex.Message);
                //throw;
            }
            return false;
        }

        private static bool ValidateSettings()
        {
            if (!ValidateOption_S) return false; // This must be done first so the httpConnection can be set first
            if (!ValidateOption_U) return false;
            if (!ValidateOption_P) return false;
            if (!ValidateOption_d) return false;
            if (!ValidateTimeout("-t", Timeout)) return false;
            if (!ValidateTimeout("-tc", ConnectTimeout)) return false;
            if (!ValidateOption_Tf) return false;
            if (!ValidateOption_Tl) return false;
            if (!ValidateOption_Td) return false;
            if (!ValidateTimeout("-Tt", TraceTimeout)) return false;
            return true;
        }

        // -S validate
        // NOTE: This must be done first so the httpConnection can be set first
        private static bool ValidateOption_S
        {
            get
            {
                // Is this a http or https connection??
                string s = Server.ToLower(CultureInfo.CurrentCulture);
                if (s.StartsWith("http://", StringComparison.CurrentCultureIgnoreCase) ||
                    s.StartsWith("https://", StringComparison.CurrentCultureIgnoreCase))
                {
                    httpConnection = true;
                    if (_DEBUGMODE) Console.WriteLine("Http Server:*" + Server);
                    if (!CheckValidChars(Properties.Resources.locNameServer,
                                8, -1, "", Server)) return false;
                }
                else
                {
                    // normal client-server connections -- either just the server or multi-instance
                    httpConnection = false;
                    if (Server.Contains("\\")) // backslash anywhere on line?
                    {
                        // multi-instance server name (i.e. <server>\<instance>
                        string[] ParsedServer = Server.Split(new Char[] { '\\' }, 2);
                        string partServer = ParsedServer[0];
                        string partInstance = ParsedServer[1];
                        if (_DEBUGMODE) Console.WriteLine("Server:*" + partServer);
                        if (_DEBUGMODE) Console.WriteLine("Instance:*" + partInstance);
                        // Check for valid server and instance name
                        // Note: the \ character not in Invalid char list since we support named instances
                        if (!CheckValidChars(Properties.Resources.locNameServer,
                                    1, -1, "", partServer)) return false;
                        if (!CheckValidChars(Properties.Resources.locNameInstance,
                                    1, -1, "", partInstance)) return false;
                        Server = partServer;
                        Instance = partInstance;
                    }
                    else
                    {
                        // just a plain old server name
                        if (_DEBUGMODE) Console.WriteLine("Server:*" + Server);
                        if (!CheckValidChars(Properties.Resources.locNameServer,
                                    1, -1, "", Server)) return false;
                    }
                }
                return true;
            }
        }

        // --------------------
        // -U validate
        private static bool ValidateOption_U
        {
            get
            {
                if (UserName.Length > 0)
                {
                    if (UserName.Contains("\\"))
                    {
                        string[] ParsedUserName = UserName.Split(new Char[] { '\\' }, 2);
                        Domain = ParsedUserName[0];
                        UserName = ParsedUserName[1];
                    }
                    else if (!httpConnection)
                    {
                        // For a TCP/IP connection, the username must be in the format <domain>\<username>
                        Console.WriteLine(Msg(Properties.Resources.locOptionUFormatErr));
                        return false;
                    }
                    if (!CheckValidChars(Properties.Resources.locNameUsername,
                                1, -1, "", UserName)) return false;
                    if (!CheckValidChars(Properties.Resources.locNameDomain,
                                1, -1, "", Domain)) return false;
                }
                return true;
            }
        }

        // --------------------
        // -P validate
        private static bool ValidateOption_P
        {
            get
            {
                if (Password.Length > 0)
                {
                    if (!CheckValidChars(Properties.Resources.locNamePassword,
                            0, -1, "", Password)) return false;
                }
                return true;
            }
        }

        // --------------------
        // -d validate
        private static bool ValidateOption_d
        {
            get
            {
                if (Database.Length > 0)
                {
                    if (!CheckValidChars(Properties.Resources.locNameDatabase,
                            1, 128, "", Database)) return false;
                }
                return true;
            }
        }


        // --------------------
        // -Tf validate
        private static bool ValidateOption_Tf
        {
            get
            {
                // only 2 supported options -- validate their names here
                TraceFormat = TraceFormat.ToLower(CultureInfo.CurrentCulture);
                if ((TraceFormat != "text") && (TraceFormat != "csv"))
                {
                    Console.WriteLine(Msg(Properties.Resources.locTraceInvalidFormatErr), TraceFormat);
                    return false;
                }
                return true;
            }
        }

        // --------------------
        // -Tl validate
        private static bool ValidateOption_Tl
        {
            get
            {
                // only 4 supported options -- validate their names here
                TraceLevel = TraceLevel.ToLower(CultureInfo.CurrentCulture);
                if ((TraceLevel != "high") && (TraceLevel != "medium") &&
                    (TraceLevel != "low") && (TraceLevel != "duration") &&
                    (TraceLevel != "duration-result"))
                {
                    Console.WriteLine(Msg(Properties.Resources.locTraceInvalidLevelErr), TraceLevel);
                    return false;
                }
                return true;
            }
        }

        // --------------------
        // -Td validate
        private static bool ValidateOption_Td
        {
            get
            {
                if (TraceDelim.Length > 1)
                {
                    Console.WriteLine(Msg(Properties.Resources.locTraceInvalidDelimErr), TraceDelim);
                    return false;
                }
                return true;
            }
        }

        // --------------------
        // validate a timeout value
        private static bool ValidateTimeout(string Option, string Timeout)
        {
            if (Timeout.Length > 0)
            {
                int t;
                if ((t = GetTimeout(Option, Timeout)) == -1) return false;
                if (!CheckTimeout(Option, t, maxTimeout)) return false;
            }
            return true;
        }

        // ------------------------------------------------------------
        // Get the available scripting variables from the OS
        private static void GetScriptingVariables()
        {
            GetEnvVar("ASCMDUSER", ref UserName);
            GetEnvVar("ASCMDPASSWORD", ref Password);
            GetEnvVar("ASCMDSERVER", ref Server);
            GetEnvVar("ASCMDDBNAME", ref Database);
            GetEnvVar("ASCMDQUERYTIMEOUT", ref Timeout);
            GetEnvVar("ASCMDCONNECTTIMEOUT", ref ConnectTimeout);
            GetEnvVar("ASCMDTRACEFORMAT", ref TraceFormat);
            GetEnvVar("ASCMDTRACEDELIM", ref TraceDelim);
            GetEnvVar("ASCMDTRACETIMEOUT", ref TraceTimeout);
            GetEnvVar("ASCMDTRACELEVEL", ref TraceLevel);
            GetEnvVar("ASCMDRUNINFO", ref RunInfo);
            GetEnvVar("ASCMDRANDOMSEED", ref RandomSeed);
            GetEnvVar("ASCMDTHINKTIMEMIN", ref ThinkTimeMin);
            GetEnvVar("ASCMDTHINKTIMEMAX", ref ThinkTimeMax);
            GetEnvVar("ASCMDCONNECTWAITMIN", ref ConnectWaitMin);
            GetEnvVar("ASCMDCONNECTWAITMAX", ref ConnectWaitMax);
            GetEnvVar("ASCMDEXTENDEDCONNECTSTRING", ref ExtendedConnectstring);
            GetEnvVar("ASCMDEXITFILE", ref ExitFile);
        }
        
        // Get environment variable values
        // OVERLOADED FOR STRING
        private static void GetEnvVar(string var_name, ref string var)
        {
            if (Environment.GetEnvironmentVariable(var_name) != null)
            {
                var = Environment.GetEnvironmentVariable(var_name);
            }
            //else
            //{
            //    var = ""; // empty string if not found as an environment variable
            //}
        }
        
        // Get environment variable values
        // OVERLOADED FOR INTEGER
        private static void GetEnvVar(string var_name, ref int var)
        {
            if (Environment.GetEnvironmentVariable(var_name) != null)
            {
                string value = Environment.GetEnvironmentVariable(var_name);
                if (!Int32.TryParse(value, out var)) var = 0;
            }
            //else
            //{
            //    var = 0; // zero if not found as an environment variable
            //}
        }

        private static void SetScriptingVariables()
        {
            // The -v entries are added to the substituteWith table as they are parsed
            // Here we add command-line entries to the substitution table
            //  * = read-only, cannot be set by outside environments
            // ** = set by ValidateSettings
            substituteWith.Add("ASCMDUSER", UserName);
            substituteWith.Add("ASCMDDOMAIN", Domain);                               // **
            substituteWith.Add("ASCMDPASSWORD", Password);
            substituteWith.Add("ASCMDSERVER", Server);
            substituteWith.Add("ASCMDINSTANCE", Instance);                           // **
            substituteWith.Add("ASCMDHTTPCONNECTION", httpConnection.ToString());    // **
            substituteWith.Add("ASCMDDBNAME", Database);
            substituteWith.Add("ASCMDINPUTFILE", InputFile);                         // *
            substituteWith.Add("ASCMDOUTPUTFILE", OutputFile);                       // *
            substituteWith.Add("ASCMDOUTPUTRESULTSTATFILE", OutputResultStatFile);   // *
            substituteWith.Add("ASCMDRUNINFO", RunInfo);
            substituteWith.Add("ASCMDQUERYTIMEOUT", Timeout);
            substituteWith.Add("ASCMDCONNECTTIMEOUT", ConnectTimeout);
            substituteWith.Add("ASCMDTRACEFILE", TraceFile);                         // *
            substituteWith.Add("ASCMDTRACEFORMAT", TraceFormat);
            substituteWith.Add("ASCMDTRACEDELIM", TraceDelim);
            substituteWith.Add("ASCMDTRACETIMEOUT", TraceTimeout);
            substituteWith.Add("ASCMDTRACELEVEL", TraceLevel);
            substituteWith.Add("ASCMDRANDOMSEED", RandomSeed.ToString(CultureInfo.CurrentCulture));
            substituteWith.Add("ASCMDTHINKTIMEMIN", ThinkTimeMin.ToString(CultureInfo.CurrentCulture));
            substituteWith.Add("ASCMDTHINKTIMEMAX", ThinkTimeMax.ToString(CultureInfo.CurrentCulture));
            substituteWith.Add("ASCMDCONNECTWAITMIN", ConnectWaitMin.ToString(CultureInfo.CurrentCulture));
            substituteWith.Add("ASCMDCONNECTWAITMAX", ConnectWaitMax.ToString(CultureInfo.CurrentCulture));
            substituteWith.Add("ASCMDEXTENDEDCONNECTSTRING", ExtendedConnectstring);
            substituteWith.Add("ASCMDEXITFILE", ExitFile);
        }

        private static bool CheckValidChars(string TypeOfCheck, int MinLen, int MaxLen, string InvalidChars, string TestString)
        {
            if (MinLen >= 0) // negative MinLen means don't check it
                if (TestString.Length < MinLen)
                {
                    Console.WriteLine(Msg(Properties.Resources.locMinErr), TypeOfCheck, TestString, TestString.Length.ToString(CultureInfo.CurrentCulture), MinLen.ToString(CultureInfo.CurrentCulture));
                    return false;
                }
            if (MaxLen >= 0) // negative MaxLen means don't check it
                if (TestString.Length > MaxLen)
                {
                    Console.WriteLine(Msg(Properties.Resources.locMaxErr), TypeOfCheck, TestString, TestString.Length.ToString(CultureInfo.CurrentCulture), MaxLen.ToString(CultureInfo.CurrentCulture));
                    return false;
                }
            if (TestString.Length > 0) // if we don't have any invalid characters provided, then don't check
            {
                int pos = TestString.IndexOfAny(InvalidChars.ToCharArray()) + 1;
                if (pos > 0)
                {
                    Console.WriteLine(Msg(Properties.Resources.locInvalidCharErr), TypeOfCheck, TestString, pos.ToString(CultureInfo.CurrentCulture));
                    return false;
                }
            }
            return true;
        }

        private static int GetTimeout(string TypeOfCheck, string Timeout)
        {
            int ReturnTimeout;
            if (Int32.TryParse(Timeout.ToString((CultureInfo.CurrentCulture)),
                out ReturnTimeout))
            {
                return ReturnTimeout;
            }
            else
            {
                Console.WriteLine(Msg(Properties.Resources.locIntegerErr), TypeOfCheck, Timeout);
                return -1;
            }
        }

        private static bool CheckTimeout(string TypeOfCheck, int Timeout, int MaxTimeout)
        {
            if (MaxTimeout > 0) // -1 maxTimeout won't run check
            {
                if ((Timeout <= 0) || (Timeout > MaxTimeout))
                {
                    Console.WriteLine(Msg(Properties.Resources.locRangeErr), TypeOfCheck, Timeout, MaxTimeout);
                    return false;
                }
            }
            return true;
        }

        private static bool OptionSeen(string opt)
        {
            Console.WriteLine(Msg(Properties.Resources.locRepeatedOption), opt);
            return false;
        }

        private static bool MissingArg(string opt)
        {
            Console.WriteLine(Msg(Properties.Resources.locParseMissingArgErr), opt);
            return false;
        }

        // --------------------------------------------------------------------
        // Supporting routine -- to show the help message
        private static void ShowHelp()
        {
            string msg = "\n" +
            "usage: ascmd.exe" +
            "\n  [-S server[:port][\\instance]] " +
            "\n       || http[s]://server:port/<vdir>/msmdpump.dll " +
            "\n  [-U domain\\username]   [-P password] " +
            "\n  [-d database]          [-xc extended-connect-string] " +
            "\n  [-i input-file]        [-o output-file] " +
            "\n  [-t query-timeout-sec] [-tc connect-timeout-sec] " +
            "\n  [-T trace-file]        [-Tt trace-timeout-sec] " +
            "\n  [-Tf text|csv]         [-Td delim-char] " +
            "\n  [-ThinkTimeMin sec]    [-ThinkTimeMax sec] " +
            "\n  [-ConnectWaitMin sec]  [-ConnectWaitMax sec] " +
            "\n  [-Tl high|medium|low|duration|duration-result] " +
            "\n  [-oResultStat statistics-output-file] " +
            "\n  [-NoResultStatHeader] " +
            "\n  [-RunInfo run-info-string] " +
            "\n  [-RandomSeed seed-int] " +
            "\n  [-Xf exit-file] " +
            "\n  [-v var=value...] " +
            "\n  [-Q \"cmdline XMLA script, MDX query or DMX statement\" " +
            "\n  [-? show syntax summary] " +
            "\n\n Note: either -i or -Q must be specified, but not both.";
            // OK write it out
            Console.WriteLine(msg);
        }
    }
}

namespace Microsoft.Samples.SqlServer.ASCmd.RandomHelper
{
    /// <summary>
    /// ran2 random number generator.
    /// </summary>
    ///
    /// This is the Numerical Recipes ran2 random number generator.
    /// Long period (> 2 x 10^18) random number generator of L'Ecuyer
    /// with Bays-Durham shuffle and added safeguards.
    /// Returns a uniform random deviate between 0.0 and 1.0 (exclusive
    /// of the endpoint values).
    /// 
    /// The motivation of this class is to improve upon System.Random.
    /// We were using consecutive seed values, and found bad correlations
    /// between parallel streams.  
    /// See http://www-cs-faculty.stanford.edu/~knuth/news02.html#rng, where 
    /// Don Knuth describes the problem and his recommendation for initializing his subtractive RNG.
    /// 
    /// Another approach is to transform the seed, and also use that to consume a count
    /// of initial values based on that seed.
    /// 
    /// Another approach is to initialize using Knuth's code.
    /// This is a little tricky in C# because we need to overwrite the private
    /// members, and requires serializing to a byte stream, overwriting the bytes,
    /// then deserializing from the bytes stream.
    /// 
    [Serializable]
    public class HighPerformanceRandom //: System.Random
    {
        /*
        public override int Next()
        {
            throw new NotImplementedException();
        }
        public override double NextDouble()
        {
            return NextInternal();
        }
        */

        /// <summary>
        // Returns a 32-bit signed integer greater than or equal to zero, and less than maxValue; 
        // that is, the range of return values includes zero but not maxValue.
        /// </summary>
        public int Next(int maxValue)
        {
            return Next(0, maxValue);
        }

        /// <summary>
        // Returns a 32-bit signed integer greater than or equal to minValue and less than maxValue; 
        // that is, the range of return values includes minValue but not maxValue. 
        // If minValue equals maxValue, minValue is returned.
        /// <summary>
        public int Next(int minValue, int maxValue)
        {
            double d = NextInternal();
            if (minValue >= maxValue)
                return minValue;
            int j = minValue + (int)((maxValue - minValue) * d);
            return j;
        }

        public HighPerformanceRandom()
        {
            throw new NotImplementedException();
        }

        public HighPerformanceRandom(int seed)
        {
            SetSeed(seed);
        }

        public void SetSeed(int seed)
        {
            // Pick a seed if user chooses default (<=0).
            // Note that clock time may introduce correlation if many instances are started at the same time,
            // since clock tick granularity is about 16 millisec, so different client runs
            // should just use client number (e.g. 1, 2, 3, etc.) which also gives a
            // reproducibile sequence.
            if (seed <= 0)
                seed = Guid.NewGuid().GetHashCode();
            //Seed = (int)(DateTime.Now.Ticks);
            else
                seed = -seed;

            // Note that NR does initialization if Dum<0, and we keep code flavor.
            // Be sure to prevent Seed==0.
            if (seed <= 0)
            {
                if (-seed < 1)
                    seed = 1;
                else
                    seed = -seed;
            }
            _Dum = seed;
            _Dum2 = _Dum;

            // Load the shuffle table, after 8 warmups.
            _iv = new int[NTAB];
            for (int j = NTAB + 7; j >= 0; j--)
            {
                int k = _Dum / IQ1;
                _Dum = IA1 * (_Dum - k * IQ1) - k * IR1;
                if (_Dum < 0)
                    _Dum += IM1;
                if (j < NTAB)
                    _iv[j] = _Dum;
            }
            _iy = _iv[0];
        }

        private double NextInternal()
        {
            // Compute Dum=(Dum*IA1)%IM1 without overflows by Schrage's method.
            int k = _Dum / IQ1;
            _Dum = IA1 * (_Dum - k * IQ1) - k * IR1;
            if (_Dum < 0)
                _Dum += IM1;

            // Compute Dum2=(Dum2*IA2)%IM2.
            k = _Dum2 / IQ2;
            _Dum2 = IA2 * (_Dum2 - k * IQ2) - k * IR2;
            if (_Dum2 < 0)
                _Dum2 += IM2;

            // Here Dum is shuffled.
            // Dum and Dum2 are combined to generate output.
            int j = _iy / NDIV;     // Will be in range 0..NTAB-1.
            _iy = _iv[j] - _Dum2;
            _iv[j] = _Dum;
            if (_iy < 1)
                _iy += IMM1;
            double temp = AM * _iy;
            if (temp > RNMX)
                return RNMX;    // Avoid endpoint value.
            else
                return temp;
        }

        private class TestPoint
        {
            public int Dum; public int Dum2; public int iy; public double dx;
            public TestPoint(int dum, int dum2, int y, double x) { Dum = dum; Dum2 = dum2; iy = y; dx = x; }
        };

        // Compare the first 50 or so numbers.
        public static void TestFirst50()
        {
            // Values taken from the C version.
            TestPoint[] rg = new TestPoint[] {
                //                    Dum,       Dum2,          iy,              x
                new TestPoint(  1454538876,       40692,   612850790, 0.285380899906),
                new TestPoint(   819059838,  1655838864,   544082547, 0.253358185291),
                new TestPoint(  1113702789,  2103410263,   200722134, 0.093468531966),
                new TestPoint(  1271983233,  1872071452,  1306737071, 0.608496904373),
                new TestPoint(  1776642162,   652912057,  1940080159, 0.903420269489),
                new TestPoint(   263600716,  1780294415,   420634462, 0.195873185992),
                new TestPoint(  1427272131,   535353314,   994185124, 0.462953537703),
                new TestPoint(   689175412,   525453832,  2016532872, 0.939021348953),
                new TestPoint(   828503285,  1422611300,   273193743, 0.127215757966),
                new TestPoint(  1026683959,  1336516156,   893205208, 0.415931105614),
                new TestPoint(   371375236,   498340277,  1146195661, 0.533738970757),
                new TestPoint(  1769920907,  1924298326,   230738686, 0.107446074486),
                new TestPoint(  1902232084,  2007787254,   858287020, 0.399671047926),
                new TestPoint(   507202204,  2020508212,  1396661036, 0.650371015072),
                new TestPoint(  1469320506,  2118231989,    58136255, 0.027071803808),
                new TestPoint(  1733222833,  1554910725,   165302143, 0.076974809170),
                new TestPoint(   196772577,  1123836963,   148146270, 0.068985983729),
                new TestPoint(   983154120,   514716691,  1829539448, 0.851945757866),
                new TestPoint(   177567083,   445999725,  1368689500, 0.637345731258),
                new TestPoint(  1293632758,   238604751,  1230715755, 0.573096692562),
                new TestPoint(   477376060,   532080813,  1937627442, 0.902278125286),
                new TestPoint(  2006855518,   504813878,  1906270400, 0.887676358223),
                new TestPoint(  1463825993,  1207612141,   799243377, 0.372176706791),
                new TestPoint(   919103077,  1438105654,   746284058, 0.347515612841),
                new TestPoint(  1334506703,   472649818,   446453259, 0.207896009088),
                new TestPoint(  1772419847,   205072612,  1222199519, 0.569131016731),
                new TestPoint(   963089783,  1841722389,   783137233, 0.364676713943),
                new TestPoint(   482038927,   491794886,   842711817, 0.392418295145),
                new TestPoint(  1755745675,  1867189230,   787496536, 0.366706669331),
                new TestPoint(  1630159468,  1701490540,   928031949, 0.432148575783),
                new TestPoint(  1535209990,    40786521,   330588715, 0.153942376375),
                new TestPoint(  1125220245,  1827928504,  1346239017, 0.626891434193),
                new TestPoint(   422501572,  1831677004,  1609439316, 0.749453604221),
                new TestPoint(   987294072,  1894317675,   732380379, 0.341041207314),
                new TestPoint(   477372060,  1805707394,  1783254487, 0.830392599106),
                new TestPoint(  1846799518,  1700779863,   559637130, 0.260601371527),
                new TestPoint(   779026859,  1186685623,  2074500728, 0.966014742851),
                new TestPoint(  1256819081,   299661202,   528842083, 0.246261298656),
                new TestPoint(   588628800,   402892262,  1386554594, 0.645664811134),
                new TestPoint(  1940567779,   603657338,  1966327796, 0.915642797947),
                new TestPoint(  1168437952,  1109280134,   795570357, 0.370466321707),
                new TestPoint(  1011561255,   873649147,   756510321, 0.352277576923),
                new TestPoint(   841862146,  1090902678,  2068142139, 0.963053762913),
                new TestPoint(   844740826,   382432447,   874386634, 0.407168030739),
                new TestPoint(    68129944,  1276424170,   258785820, 0.120506539941),
                new TestPoint(   994937769,  1218837426,   683394658, 0.318230450153),
                new TestPoint(  1389597872,   803438887,  1821416735, 0.848163306713),
                new TestPoint(   724837012,   247923428,  2077127217, 0.967237770557),
                new TestPoint(  1862679853,  1770607073,  1221617315, 0.568859934807),
                new TestPoint(   559616901,  1474978066,  1635595279, 0.761633455753),
                new TestPoint(   699565213,  1941426420,   183528431, 0.085462085903),
                new TestPoint(  2101672840,  1052083627,  2078554055, 0.967902183533),
                new TestPoint(   880692680,  1305390819,   557289034, 0.259507954121),
                new TestPoint(  1979112253,   961332483,  1965177938, 0.915107309818),
                new TestPoint(  1593822354,  2131285451,  1184636063, 0.551639199257),
                new TestPoint(  1388302545,   150503477,  1619417430, 0.754100024700),
                new TestPoint(   433227946,  1812315535,  1034733240, 0.481835246086),
                new TestPoint(   695710708,    16345161,   293867502, 0.136842727661),
                new TestPoint(   338842743,  1544921121,  1727782686, 0.804561555386),
                new TestPoint(  1389785183,   501233406,   953305470, 0.443917483091), };

            HighPerformanceRandom r = new HighPerformanceRandom(1);

            Console.WriteLine("L'Ecuyer LCG with Bays-Durham shuffle.");
            Console.WriteLine("i, Dum, Dum2, iy, x");
            double dx = 0.0;
            bool fGotError = false;
            for (int i = 0; i < rg.Length; i++)
            {
                dx = r.NextInternal();
                Console.WriteLine("Expect [{0:######0}]: {1}, {2}, {3}, {4:f12}", i, rg[i].Dum, rg[i].Dum2, rg[i].iy, rg[i].dx);
                Console.WriteLine("Got    [{0:######0}]: {1}, {2}, {3}, {4:f12}", i, r._Dum, r._Dum2, r._iy, dx);
                if (rg[i].Dum != r._Dum
                    || rg[i].Dum2 != r._Dum2
                    || rg[i].iy != r._iy
                    || System.Math.Abs(rg[i].dx - dx) > EPS)
                {
                    fGotError = true;
                    Console.WriteLine("***** Diff *****");
                }
            }

            Console.WriteLine("{0}", !fGotError ? "OK" : "Error");
        }

        // Show a matrix of values produced with different seeds.
        public static void TestShowWithSeeds()
        {
            const int NUMSEED = 20;
            const int NUMVAL = 40;

            // For this scenario, the system RNG performs poorly (has patterns).
            Console.WriteLine("System.Random");
            for (int Seed = 1; Seed <= NUMSEED; Seed++)
            {
                System.Random r = new System.Random(Seed);
                Console.Write("{0:00}", Seed);
                for (int j = 0; j < NUMVAL; j++)
                    Console.Write(" {0:00}", r.Next(5, 25));
                Console.WriteLine("");
            }

            Console.WriteLine("ASPPerfRand_ran2: LCG from L'Ecuyer with Bays-Durham shuffle)");
            for (int Seed = 1; Seed <= NUMSEED; Seed++)
            {
                HighPerformanceRandom r = new HighPerformanceRandom(Seed);
                Console.Write("{0:00}", Seed);
                for (int j = 0; j < NUMVAL; j++)
                    Console.Write(" {0:00}", r.Next(5, 25));
                Console.WriteLine("");
            }
        }

        // Constants.
        private const int IM1 = 2147483563;
        private const int IM2 = 2147483399;
        private const double AM = (1.0 / IM1);
        private const int IMM1 = (IM1 - 1);
        private const int IA1 = 40014;
        private const int IA2 = 40692;
        private const int IQ1 = 53668;
        private const int IQ2 = 52774;
        private const int IR1 = 12211;
        private const int IR2 = 3791;
        private const int NTAB = 32;
        private const int NDIV = (1 + IMM1 / NTAB);
        private const double EPS = 1.2e-7;
        private const double RNMX = (1.0 - EPS);

        // Vars for state of LCG and shuffle table.
        private Int32 _Dum;
        private Int32 _Dum2;
        private Int32 _iy;
        private Int32[] _iv;
    }
}

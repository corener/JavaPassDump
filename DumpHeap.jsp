<%@ page import="java.util.*,javax.crypto.*,javax.crypto.spec.*"%>
<%@ page import="com.sun.management.HotSpotDiagnosticMXBean" %>
<%@ page import="java.security.AccessController" %>
<%@ page import="java.security.PrivilegedExceptionAction" %>
<%@ page import="javax.management.MBeanServer" %>
<%@ page import="java.lang.management.ManagementFactory" %>
<%@ page import="javax.management.ObjectName" %>
<%@ page import="java.io.StringWriter" %>
<%@ page import="java.io.PrintWriter" %>
<%!
    public static class DumpHeap {
        private static final String HOTSPOT_BEAN_NAME = "com.sun.management:type=HotSpotDiagnostic";
        private static volatile HotSpotDiagnosticMXBean hotspotMBean;

        public static void dumpHeap(String fileName, boolean live) {
            initHotspotMBean();
            try {
                hotspotMBean.dumpHeap(fileName, live);
            } catch (RuntimeException re) {
                throw re;
            } catch (Exception exp) {
                throw new RuntimeException(exp);
            }
        }

        private static void initHotspotMBean() {
            if (hotspotMBean == null) {
                synchronized (DumpHeap.class) {
                    if (hotspotMBean == null) {
                        hotspotMBean = getHotspotMBean();
                    }
                }
            }
        }

        private static HotSpotDiagnosticMXBean getHotspotMBean() {
            try {
                return AccessController.doPrivileged(
                        new PrivilegedExceptionAction<HotSpotDiagnosticMXBean>() {
                            //@Override
                            public HotSpotDiagnosticMXBean run() throws Exception {
                                MBeanServer server = ManagementFactory.getPlatformMBeanServer();
                                Set<ObjectName> s = server.queryNames(new ObjectName(HOTSPOT_BEAN_NAME), null);
                                Iterator<ObjectName> itr = s.iterator();
                                if (itr.hasNext()) {
                                    ObjectName name = itr.next();
                                    HotSpotDiagnosticMXBean bean =
                                            ManagementFactory.newPlatformMXBeanProxy(server,
                                                    name.toString(), HotSpotDiagnosticMXBean.class);
                                    return bean;
                                } else {
                                    return null;
                                }
                            }
                        });
            } catch (Exception exp) {
                throw new UnsupportedOperationException(exp);
            }
        }
    }


%><%
    try {
        String fileName = "/tmp/dumpHeap.hprof";
        boolean live = true;
        DumpHeap.dumpHeap(fileName, live);
    }catch (Exception e){
        StringWriter errors = new StringWriter();
        e.printStackTrace(new PrintWriter(errors));
        out.println(errors.toString());
    }
    out.print("done");
%>
import Http from "axios";
import store from "store";
import constants from "../constants/constants";

export const authHeaderObject = () => ({
  "access-token": store.get("access-token"),
  uid: store.get("uid"),
  expiry: store.get("expiry"),
  client: store.get("client"),
});

export const authProvider = {
  login: async (params) => {
    const { data, status, headers } = await Http.post(
      constants.AUTH_LOGIN_PATH,
      {
        email: params.username,
        password: params.password,
      }
    );

    if (status < 200 || status >= 300) {
      throw new Error(data.error);
    }

    Object.keys(authHeaderObject()).forEach((itemName) =>
      store.set(itemName, headers[itemName])
    );

    return;
  },

  logout: async () => {
    const headers = { ...authHeaderObject() };

    Object.keys(authHeaderObject()).forEach((item) => store.remove(item));

    if (headers["access-token"]) {
      await Http.delete(constants.AUTH_LOGOUT_PATH, { headers });
    }

    return Promise.resolve();
  },

  checkAuth: () =>
    store.get("access-token") &&
    store.get("expiry") > Math.floor(Date.now() / 1000)
      ? Promise.resolve()
      : Promise.reject("auth failure. token expired."),

  checkError: ({ status }) =>
    status === 403 || status === 401 ? Promise.reject() : Promise.resolve(),

  getPermissions: () => Promise.resolve(),
};

export default authProvider;
